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
