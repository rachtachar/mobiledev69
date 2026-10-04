from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status
from expenses.models import FriendRequest

class FriendRequestTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user1 = User.objects.create_user(username='user1', password='password123', first_name='User One')
        self.user2 = User.objects.create_user(username='user2', password='password123', first_name='User Two')
        self.user3 = User.objects.create_user(username='user3', password='password123', first_name='User Three')

    def test_send_friend_request(self):
        self.client.force_authenticate(user=self.user1)
        response = self.client.post('/api/friends/requests/', {'username': 'user2'})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(FriendRequest.objects.filter(from_user=self.user1, to_user=self.user2, status='pending').exists())

    def test_cannot_add_self(self):
        self.client.force_authenticate(user=self.user1)
        response = self.client.post('/api/friends/requests/', {'username': 'user1'})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cannot_add_nonexistent_user(self):
        self.client.force_authenticate(user=self.user1)
        response = self.client.post('/api/friends/requests/', {'username': 'nonexistent'})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_accept_friend_request(self):
        req = FriendRequest.objects.create(from_user=self.user1, to_user=self.user2, status='pending')
        self.client.force_authenticate(user=self.user2)

        # Check pending requests list
        resp = self.client.get('/api/friends/requests/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data['incoming']), 1)

        # Accept
        resp_act = self.client.post(f'/api/friends/requests/{req.id}/respond/', {'action': 'accept'})
        self.assertEqual(resp_act.status_code, status.HTTP_200_OK)
        req.refresh_from_db()
        self.assertEqual(req.status, 'accepted')

        # Check friends list
        resp_friends = self.client.get('/api/friends/')
        self.assertEqual(resp_friends.status_code, status.HTTP_200_OK)
        friend_usernames = [f['username'] for f in resp_friends.data]
        self.assertIn('user1', friend_usernames)

    def test_reject_friend_request(self):
        req = FriendRequest.objects.create(from_user=self.user1, to_user=self.user2, status='pending')
        self.client.force_authenticate(user=self.user2)

        resp_act = self.client.post(f'/api/friends/requests/{req.id}/respond/', {'action': 'reject'})
        self.assertEqual(resp_act.status_code, status.HTTP_200_OK)
        req.refresh_from_db()
        self.assertEqual(req.status, 'rejected')

    def test_auto_accept_on_mutual_request(self):
        # user1 sends to user2
        FriendRequest.objects.create(from_user=self.user1, to_user=self.user2, status='pending')
        # user2 sends to user1
        self.client.force_authenticate(user=self.user2)
        response = self.client.post('/api/friends/requests/', {'username': 'user1'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(FriendRequest.objects.filter(from_user=self.user1, to_user=self.user2, status='accepted').exists())

    def test_new_user_sees_no_bills_until_involved(self):
        from expenses.models import Expense, ExpenseSplit
        # user1 creates a bill with user2
        exp = Expense.objects.create(title='Secret Bill', amount=500, payer=self.user1)
        ExpenseSplit.objects.create(expense=exp, user=self.user1, amount_owed=250, is_settled=True)
        ExpenseSplit.objects.create(expense=exp, user=self.user2, amount_owed=250, is_settled=False)

        # user1 and user2 can see it
        self.client.force_authenticate(user=self.user1)
        resp1 = self.client.get('/api/expenses/')
        self.assertEqual(len(resp1.data), 1)

        self.client.force_authenticate(user=self.user2)
        resp2 = self.client.get('/api/expenses/')
        self.assertEqual(len(resp2.data), 1)

        # user3 (uninvolved/new user) CANNOT see it
        self.client.force_authenticate(user=self.user3)
        resp3 = self.client.get('/api/expenses/')
        self.assertEqual(len(resp3.data), 0)

    def test_settle_multiple_bills_fifo(self):
        from expenses.models import Expense, ExpenseSplit
        exp1 = Expense.objects.create(title='Bill 1', amount=200, payer=self.user1)
        ExpenseSplit.objects.create(expense=exp1, user=self.user1, amount_owed=100, is_settled=True)
        split1 = ExpenseSplit.objects.create(expense=exp1, user=self.user2, amount_owed=100, is_settled=False)

        exp2 = Expense.objects.create(title='Bill 2', amount=200, payer=self.user1)
        ExpenseSplit.objects.create(expense=exp2, user=self.user1, amount_owed=100, is_settled=True)
        split2 = ExpenseSplit.objects.create(expense=exp2, user=self.user2, amount_owed=100, is_settled=False)

        # user1 records receiving 100 from user2
        self.client.force_authenticate(user=self.user1)
        resp = self.client.post('/api/settle/', {'debtor_id': self.user2.id, 'amount': 100})
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

        split1.refresh_from_db()
        split2.refresh_from_db()
        self.assertTrue(split1.is_settled, "Bill 1 should be settled")
        self.assertFalse(split2.is_settled, "Bill 2 should remain unsettled")

        # Check balance
        bal_resp = self.client.get('/api/summary/')
        self.assertEqual(bal_resp.data['total_owed_to_you'], 100.0)

    def test_debtor_mark_paid_and_owner_verify(self):
        from expenses.models import Expense, ExpenseSplit
        exp = Expense.objects.create(title='Dinner with friends', amount=300, payer=self.user1)
        ExpenseSplit.objects.create(expense=exp, user=self.user1, amount_owed=150, is_settled=True)
        split = ExpenseSplit.objects.create(expense=exp, user=self.user2, amount_owed=150, is_settled=False)

        # 1. Debtor (user2) notifies they paid
        self.client.force_authenticate(user=self.user2)
        resp_paid = self.client.post(f'/api/splits/{split.id}/mark-paid/')
        self.assertEqual(resp_paid.status_code, status.HTTP_200_OK)
        split.refresh_from_db()
        self.assertTrue(split.pending_verification)
        self.assertFalse(split.is_settled)

        # 2. Bill owner (user1) verifies and confirms
        self.client.force_authenticate(user=self.user1)
        resp_verify = self.client.post(f'/api/splits/{split.id}/verify/', {'action': 'confirm'})
        self.assertEqual(resp_verify.status_code, status.HTTP_200_OK)
        split.refresh_from_db()
        self.assertFalse(split.pending_verification)
        self.assertTrue(split.is_settled)

        # 3. Check balance is cleared
        bal_resp = self.client.get('/api/summary/')
        self.assertEqual(bal_resp.data['total_owed_to_you'], 0.0)



