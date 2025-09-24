'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  Users,
  Search,
  Edit,
  Trash2,
  Plus,
  Eye,
  Mail,
  Calendar,
  CheckCircle,
  XCircle
} from 'lucide-react';

interface User {
  id: string;
  email: string;
  firstName?: string;
  lastName?: string;
  isVerified: boolean;
  isCreator: boolean;
  createdAt: string;
  lastLoginAt?: string;
  emailVerifiedAt?: string;
  _count?: {
    listings: number;
    favorites: number;
  };
}

export default function UsersManagement() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filter, setFilter] = useState('all');
  const [error, setError] = useState<string | null>(null);

  const fetchUsers = async () => {
    setLoading(true);
    setError(null);

    try {
      // Get admin token from localStorage
      const adminToken = localStorage.getItem('adminToken');
      if (!adminToken) {
        setError('No admin token found. Please log in again.');
        setLoading(false);
        return;
      }

      // Fetch ALL users from your Railway backend
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/users?limit=500`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        if (response.status === 401) {
          setError('Authentication failed. Please log in again.');
        } else if (response.status === 403) {
          setError('Access denied. Admin privileges required.');
        } else {
          setError(`API error: ${response.status}`);
        }
        setLoading(false);
        return;
      }

      const data = await response.json();
      console.log('Users API Response:', data);

      // Handle the actual API response structure: { users: [...], pagination: {...} }
      if (data.users && Array.isArray(data.users)) {
        const realUsers = data.users.map((user: any) => ({
          id: user.id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          isVerified: user.isVerified || false,
          isCreator: user.isCreator || false,
          createdAt: user.createdAt,
          lastLoginAt: user.lastLoginAt,
          emailVerifiedAt: user.emailVerifiedAt,
          _count: {
            listings: user._count?.listings || 0,
            favorites: user._count?.favorites || 0
          }
        }));

        setUsers(realUsers);
        console.log(`Loaded ${realUsers.length} real users from database`);
      } else {
        setError('No users data received from API');
      }

    } catch (error) {
      console.error('Error fetching users:', error);
      setError('Failed to connect to backend server');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleBulkAction = async (action: 'verify' | 'unverify' | 'delete') => {
    if (selectedUsers.length === 0) return;

    const confirmAction = confirm(`Are you sure you want to ${action} ${selectedUsers.length} users?`);
    if (!confirmAction) return;

    console.log(`🔥 Starting bulk ${action} for users:`, selectedUsers);

    try {
      const adminToken = localStorage.getItem('adminToken');

      if (!adminToken) {
        console.error('❌ No admin token found');
        alert('No admin token found. Please log in again.');
        return;
      }

      let successCount = 0;
      let failCount = 0;

      for (const userId of selectedUsers) {
        console.log(`🔄 Processing ${action} for user ${userId}...`);

        const endpoint = action === 'delete'
          ? `/api/admin/users/${userId}`
          : `/api/admin/users/${userId}`;

        const method = action === 'delete' ? 'DELETE' : 'PATCH';
        const body = action !== 'delete' ? {
          isVerified: action === 'verify'
        } : undefined;

        const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}${endpoint}`, {
          method,
          headers: {
            'Authorization': `Bearer ${adminToken}`,
            'Content-Type': 'application/json'
          },
          body: body ? JSON.stringify(body) : undefined
        });

        console.log(`📋 Response for user ${userId}:`, response.status, response.statusText);

        if (response.ok) {
          const result = await response.json();
          console.log(`✅ Success for user ${userId}:`, result);
          successCount++;
        } else {
          const error = await response.text();
          console.error(`❌ Failed for user ${userId}:`, error);
          failCount++;
        }
      }

      console.log(`📊 Bulk ${action} completed: ${successCount} success, ${failCount} failed`);

      if (successCount > 0) {
        alert(`Successfully ${action}ed ${successCount} users${failCount > 0 ? ` (${failCount} failed)` : ''}`);
      } else {
        alert(`Failed to ${action} any users. Check console for details.`);
      }

      setSelectedUsers([]);
      fetchUsers(); // Reload real data
    } catch (error) {
      console.error(`❌ Error performing bulk ${action}:`, error);
      alert(`Error performing bulk ${action}: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  const filteredUsers = users.filter(user => {
    const matchesSearch = user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         `${user.firstName || ''} ${user.lastName || ''}`.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesFilter = filter === 'all' ||
                         (filter === 'verified' && user.isVerified) ||
                         (filter === 'creators' && user.isCreator) ||
                         (filter === 'recent' && user.lastLoginAt);

    return matchesSearch && matchesFilter;
  });

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950 p-6">
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="flex items-center gap-3">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
            <span className="text-gray-400">Loading real users from database...</span>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950 p-6">
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="text-center">
            <div className="text-red-400 text-lg mb-4">❌ {error}</div>
            <button
              onClick={fetchUsers}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Retry
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950 p-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="max-w-7xl mx-auto"
      >
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
              Users Management
            </h1>
            <p className="text-gray-400 mt-2">
              Manage all platform users • {users.length} total users from database
            </p>
          </div>
          <div className="flex gap-3">
            <button
              onClick={fetchUsers}
              className="px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white hover:bg-gray-700 flex items-center gap-2"
            >
              <Eye className="w-4 h-4" />
              Refresh
            </button>
            <button className="px-4 py-2 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-lg hover:from-blue-600 hover:to-purple-700 flex items-center gap-2">
              <Plus className="w-4 h-4" />
              Add User
            </button>
          </div>
        </div>

        {/* Analytics Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Total Users</p>
                <p className="text-2xl font-bold text-white">{users.length}</p>
              </div>
              <Users className="w-8 h-8 text-blue-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Recent Logins</p>
                <p className="text-2xl font-bold text-white">{users.filter(u => u.lastLoginAt).length}</p>
              </div>
              <CheckCircle className="w-8 h-8 text-green-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Verified Users</p>
                <p className="text-2xl font-bold text-white">{users.filter(u => u.isVerified).length}</p>
              </div>
              <Mail className="w-8 h-8 text-purple-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">New Today</p>
                <p className="text-2xl font-bold text-white">
                  {users.filter(u => {
                    const today = new Date();
                    const userDate = new Date(u.createdAt);
                    return userDate.toDateString() === today.toDateString();
                  }).length}
                </p>
              </div>
              <Calendar className="w-8 h-8 text-yellow-400" />
            </div>
          </div>
        </div>

        {/* Controls */}
        <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6 mb-6">
          <div className="flex flex-col lg:flex-row gap-4 items-center justify-between">
            {/* Search */}
            <div className="relative flex-1 max-w-md">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
              <input
                type="text"
                placeholder="Search users..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* Filters */}
            <div className="flex gap-2">
              {['all', 'verified', 'creators', 'recent'].map((f) => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className={`px-3 py-1 rounded-lg text-sm font-medium transition-all ${
                    filter === f
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
                  }`}
                >
                  {f === 'creators' ? 'Creators' : f === 'recent' ? 'Recent Logins' : f.charAt(0).toUpperCase() + f.slice(1)}
                </button>
              ))}
            </div>

            {/* Bulk Actions */}
            {selectedUsers.length > 0 && (
              <div className="flex gap-2">
                <button
                  onClick={() => handleBulkAction('verify')}
                  className="px-3 py-1 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm"
                >
                  Verify ({selectedUsers.length})
                </button>
                <button
                  onClick={() => handleBulkAction('unverify')}
                  className="px-3 py-1 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 text-sm"
                >
                  Unverify ({selectedUsers.length})
                </button>
                <button
                  onClick={() => handleBulkAction('delete')}
                  className="px-3 py-1 bg-red-600 text-white rounded-lg hover:bg-red-700 text-sm"
                >
                  Delete ({selectedUsers.length})
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Users Table */}
        <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl overflow-hidden">
          {filteredUsers.length === 0 && !loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="text-center">
                <div className="text-gray-400 text-lg">No users found</div>
                <div className="text-gray-500 text-sm mt-2">
                  {users.length === 0 ? 'No users in database' : 'Try adjusting your search or filters'}
                </div>
              </div>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-800/50">
                  <tr>
                    <th className="p-4 text-left">
                      <input
                        type="checkbox"
                        checked={selectedUsers.length === filteredUsers.length && filteredUsers.length > 0}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedUsers(filteredUsers.map(u => u.id));
                          } else {
                            setSelectedUsers([]);
                          }
                        }}
                        className="rounded border-gray-600 bg-gray-700 text-blue-600"
                      />
                    </th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">User</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Status</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Activity</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Joined</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredUsers.map((user) => (
                    <tr key={user.id} className="border-t border-gray-800 hover:bg-gray-800/30">
                      <td className="p-4">
                        <input
                          type="checkbox"
                          checked={selectedUsers.includes(user.id)}
                          onChange={(e) => {
                            if (e.target.checked) {
                              setSelectedUsers([...selectedUsers, user.id]);
                            } else {
                              setSelectedUsers(selectedUsers.filter(id => id !== user.id));
                            }
                          }}
                          className="rounded border-gray-600 bg-gray-700 text-blue-600"
                        />
                      </td>
                      <td className="p-4">
                        <div>
                          <div className="font-medium text-white">
                            {user.firstName && user.lastName
                              ? `${user.firstName} ${user.lastName}`
                              : 'No name'
                            }
                          </div>
                          <div className="text-sm text-gray-400">{user.email}</div>
                          <div className="text-xs text-gray-500">
                            {user._count?.listings || 0} listings • {user._count?.favorites || 0} favorites
                          </div>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex flex-col gap-1">
                          {user.isVerified && (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                              <Mail className="w-3 h-3 mr-1" />
                              Verified
                            </span>
                          )}
                          {user.isCreator && (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                              <CheckCircle className="w-3 h-3 mr-1" />
                              Creator
                            </span>
                          )}
                          {user.lastLoginAt && (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                              <CheckCircle className="w-3 h-3 mr-1" />
                              Recent Login
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="p-4 text-sm text-gray-400">
                        {user.lastLoginAt
                          ? new Date(user.lastLoginAt).toLocaleDateString()
                          : 'Never'
                        }
                      </td>
                      <td className="p-4 text-sm text-gray-400">
                        {new Date(user.createdAt).toLocaleDateString()}
                      </td>
                      <td className="p-4">
                        <div className="flex gap-2">
                          <button className="p-1 text-blue-400 hover:text-blue-300">
                            <Eye className="w-4 h-4" />
                          </button>
                          <button className="p-1 text-green-400 hover:text-green-300">
                            <Edit className="w-4 h-4" />
                          </button>
                          <button className="p-1 text-red-400 hover:text-red-300">
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

      </motion.div>
    </div>
  );
}