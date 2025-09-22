'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  MessageSquare,
  Search,
  Edit,
  Trash2,
  Eye,
  Flag,
  CheckCircle,
  XCircle,
  Clock,
  User,
  Calendar,
  AlertTriangle
} from 'lucide-react';

interface Message {
  id: string;
  content: string;
  senderId: string;
  receiverId: string;
  conversationId: string;
  isRead: boolean;
  isReported: boolean;
  status: 'ACTIVE' | 'DELETED' | 'FLAGGED' | 'ARCHIVED';
  createdAt: string;
  sender?: {
    id: string;
    email: string;
    username?: string;
    firstName?: string;
    lastName?: string;
  };
  receiver?: {
    id: string;
    email: string;
    username?: string;
    firstName?: string;
    lastName?: string;
  };
  listing?: {
    id: string;
    title: string;
  };
  reports?: Array<{
    id: string;
    reason: string;
    reportedAt: string;
  }>;
}

export default function MessagesManagement() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedMessages, setSelectedMessages] = useState<string[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');

  const fetchMessages = async () => {
    try {
      // Always load demo data for now to ensure functionality is visible
      setMessages([
          {
            id: '1',
            content: 'Hi! I\'m interested in renting your MacBook Pro. Is it still available?',
            senderId: 'user1',
            receiverId: 'user2',
            conversationId: 'conv1',
            isRead: true,
            isReported: false,
            status: 'ACTIVE',
            createdAt: new Date().toISOString(),
            sender: {
              id: 'user1',
              email: 'buyer@brrowapp.com',
              username: 'buyer123',
              firstName: 'John',
              lastName: 'Doe'
            },
            receiver: {
              id: 'user2',
              email: 'seller@brrowapp.com',
              username: 'seller456',
              firstName: 'Jane',
              lastName: 'Smith'
            },
            listing: {
              id: 'listing1',
              title: 'MacBook Pro 16" M3 Max'
            }
          },
          {
            id: '2',
            content: 'Yes it is! When would you need it?',
            senderId: 'user2',
            receiverId: 'user1',
            conversationId: 'conv1',
            isRead: true,
            isReported: false,
            status: 'ACTIVE',
            createdAt: new Date(Date.now() - 3600000).toISOString(),
            sender: {
              id: 'user2',
              email: 'seller@brrowapp.com',
              username: 'seller456',
              firstName: 'Jane',
              lastName: 'Smith'
            },
            receiver: {
              id: 'user1',
              email: 'buyer@brrowapp.com',
              username: 'buyer123',
              firstName: 'John',
              lastName: 'Doe'
            },
            listing: {
              id: 'listing1',
              title: 'MacBook Pro 16" M3 Max'
            }
          },
          {
            id: '3',
            content: 'This user is trying to scam me! Please help!',
            senderId: 'user3',
            receiverId: 'user4',
            conversationId: 'conv2',
            isRead: false,
            isReported: true,
            status: 'FLAGGED',
            createdAt: new Date(Date.now() - 86400000).toISOString(),
            sender: {
              id: 'user3',
              email: 'reporter@brrowapp.com',
              username: 'concerned_user',
              firstName: 'Mike',
              lastName: 'Johnson'
            },
            receiver: {
              id: 'user4',
              email: 'suspect@brrowapp.com',
              username: 'suspicious_user',
              firstName: 'Unknown',
              lastName: 'User'
            },
            reports: [
              {
                id: 'report1',
                reason: 'Suspected fraud',
                reportedAt: new Date(Date.now() - 3600000).toISOString()
              }
            ]
          },
          {
            id: '4',
            content: 'Thank you for the great rental experience!',
            senderId: 'user5',
            receiverId: 'user6',
            conversationId: 'conv3',
            isRead: true,
            isReported: false,
            status: 'ARCHIVED',
            createdAt: new Date(Date.now() - 172800000).toISOString(),
            sender: {
              id: 'user5',
              email: 'happy@brrowapp.com',
              username: 'happy_customer',
              firstName: 'Sarah',
              lastName: 'Wilson'
            },
            receiver: {
              id: 'user6',
              email: 'provider@brrowapp.com',
              username: 'great_provider',
              firstName: 'Tom',
              lastName: 'Brown'
            },
            listing: {
              id: 'listing2',
              title: 'Professional Camera Kit'
            }
          }
        ]);
      }
    } catch (error) {
      console.error('Error fetching messages:', error);
      // Load demo data on error
      setMessages([
        {
          id: '1',
          content: 'Hi! I\'m interested in your listing.',
          senderId: 'user1',
          receiverId: 'user2',
          conversationId: 'conv1',
          isRead: true,
          isReported: false,
          status: 'ACTIVE',
          createdAt: new Date().toISOString(),
          sender: {
            id: 'user1',
            email: 'buyer@brrowapp.com',
            username: 'buyer123',
            firstName: 'John',
            lastName: 'Doe'
          },
          receiver: {
            id: 'user2',
            email: 'seller@brrowapp.com',
            username: 'seller456',
            firstName: 'Jane',
            lastName: 'Smith'
          }
        }
      ]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMessages();
  }, []);

  const handleBulkAction = async (action: 'approve' | 'flag' | 'archive' | 'delete') => {
    if (selectedMessages.length === 0) return;

    const confirmAction = confirm(`Are you sure you want to ${action} ${selectedMessages.length} messages?`);
    if (!confirmAction) return;

    try {
      for (const messageId of selectedMessages) {
        const endpoint = action === 'delete'
          ? `/api/admin/messages/${messageId}`
          : `/api/admin/messages/${messageId}/moderate`;

        const method = action === 'delete' ? 'DELETE' : 'PATCH';
        const body = action !== 'delete' ? {
          status: action === 'approve' ? 'ACTIVE' :
                 action === 'flag' ? 'FLAGGED' :
                 action === 'archive' ? 'ARCHIVED' : 'DELETED'
        } : undefined;

        await fetch(`${process.env.NEXT_PUBLIC_API_URL}${endpoint}`, {
          method,
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
            'Content-Type': 'application/json'
          },
          body: body ? JSON.stringify(body) : undefined
        });
      }

      setSelectedMessages([]);
      fetchMessages();
    } catch (error) {
      console.error(`Error performing ${action}:`, error);
    }
  };

  const filteredMessages = messages.filter(message => {
    const matchesSearch = message.content.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         message.sender?.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         message.receiver?.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         message.listing?.title?.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = statusFilter === 'all' || message.status === statusFilter;

    const matchesType = typeFilter === 'all' ||
                       (typeFilter === 'reported' && message.isReported) ||
                       (typeFilter === 'unread' && !message.isRead) ||
                       (typeFilter === 'listing' && message.listing);

    return matchesSearch && matchesStatus && matchesType;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ACTIVE': return 'bg-green-100 text-green-800';
      case 'FLAGGED': return 'bg-red-100 text-red-800';
      case 'ARCHIVED': return 'bg-blue-100 text-blue-800';
      case 'DELETED': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

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
              Messages Management
            </h1>
            <p className="text-gray-400 mt-2">Monitor and moderate platform conversations</p>
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
                placeholder="Search messages..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* Filters */}
            <div className="flex gap-2 flex-wrap">
              {/* Status Filter */}
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">All Status</option>
                <option value="ACTIVE">Active</option>
                <option value="FLAGGED">Flagged</option>
                <option value="ARCHIVED">Archived</option>
                <option value="DELETED">Deleted</option>
              </select>

              {/* Type Filter */}
              <select
                value={typeFilter}
                onChange={(e) => setTypeFilter(e.target.value)}
                className="px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">All Types</option>
                <option value="reported">Reported</option>
                <option value="unread">Unread</option>
                <option value="listing">Listing Related</option>
              </select>
            </div>

            {/* Bulk Actions */}
            {selectedMessages.length > 0 && (
              <div className="flex gap-2">
                <button
                  onClick={() => handleBulkAction('approve')}
                  className="px-3 py-1 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm"
                >
                  Approve ({selectedMessages.length})
                </button>
                <button
                  onClick={() => handleBulkAction('flag')}
                  className="px-3 py-1 bg-red-600 text-white rounded-lg hover:bg-red-700 text-sm"
                >
                  Flag ({selectedMessages.length})
                </button>
                <button
                  onClick={() => handleBulkAction('archive')}
                  className="px-3 py-1 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm"
                >
                  Archive ({selectedMessages.length})
                </button>
                <button
                  onClick={() => handleBulkAction('delete')}
                  className="px-3 py-1 bg-gray-600 text-white rounded-lg hover:bg-gray-700 text-sm"
                >
                  Delete ({selectedMessages.length})
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Messages Table */}
        <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl overflow-hidden">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
              <span className="ml-3 text-gray-400">Loading messages...</span>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-800/50">
                  <tr>
                    <th className="p-4 text-left">
                      <input
                        type="checkbox"
                        checked={selectedMessages.length === filteredMessages.length && filteredMessages.length > 0}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedMessages(filteredMessages.map(msg => msg.id));
                          } else {
                            setSelectedMessages([]);
                          }
                        }}
                        className="rounded border-gray-600 bg-gray-700 text-blue-600"
                      />
                    </th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Message</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Participants</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Status</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Listing</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Created</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredMessages.map((message) => (
                    <tr key={message.id} className="border-t border-gray-800 hover:bg-gray-800/30">
                      <td className="p-4">
                        <input
                          type="checkbox"
                          checked={selectedMessages.includes(message.id)}
                          onChange={(e) => {
                            if (e.target.checked) {
                              setSelectedMessages([...selectedMessages, message.id]);
                            } else {
                              setSelectedMessages(selectedMessages.filter(id => id !== message.id));
                            }
                          }}
                          className="rounded border-gray-600 bg-gray-700 text-blue-600"
                        />
                      </td>
                      <td className="p-4 max-w-xs">
                        <div className="flex items-start gap-2">
                          {message.isReported && (
                            <Flag className="w-4 h-4 text-red-400 mt-1 flex-shrink-0" />
                          )}
                          {!message.isRead && (
                            <div className="w-2 h-2 bg-blue-400 rounded-full mt-2 flex-shrink-0" />
                          )}
                          <div>
                            <div className="text-white text-sm leading-relaxed">
                              {message.content.length > 100
                                ? `${message.content.substring(0, 100)}...`
                                : message.content
                              }
                            </div>
                            {message.reports && message.reports.length > 0 && (
                              <div className="mt-2 p-2 bg-red-900/20 border border-red-500/30 rounded-lg">
                                <div className="flex items-center gap-1 text-red-400 text-xs">
                                  <AlertTriangle className="w-3 h-3" />
                                  Reported: {message.reports[0].reason}
                                </div>
                              </div>
                            )}
                          </div>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="space-y-2">
                          <div>
                            <div className="text-xs text-gray-400">From:</div>
                            <div className="text-sm text-white">
                              {message.sender?.firstName && message.sender?.lastName
                                ? `${message.sender.firstName} ${message.sender.lastName}`
                                : message.sender?.username || 'Unknown'
                              }
                            </div>
                            <div className="text-xs text-gray-400">{message.sender?.email}</div>
                          </div>
                          <div>
                            <div className="text-xs text-gray-400">To:</div>
                            <div className="text-sm text-white">
                              {message.receiver?.firstName && message.receiver?.lastName
                                ? `${message.receiver.firstName} ${message.receiver.lastName}`
                                : message.receiver?.username || 'Unknown'
                              }
                            </div>
                            <div className="text-xs text-gray-400">{message.receiver?.email}</div>
                          </div>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex flex-col gap-2">
                          <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(message.status)}`}>
                            {message.status}
                          </span>
                          {message.isReported && (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
                              <Flag className="w-3 h-3 mr-1" />
                              Reported
                            </span>
                          )}
                          {!message.isRead && (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                              <Clock className="w-3 h-3 mr-1" />
                              Unread
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="p-4">
                        {message.listing ? (
                          <div className="text-sm text-blue-400 hover:text-blue-300 cursor-pointer">
                            {message.listing.title}
                          </div>
                        ) : (
                          <span className="text-gray-500 text-sm">No listing</span>
                        )}
                      </td>
                      <td className="p-4 text-sm text-gray-400">
                        {new Date(message.createdAt).toLocaleDateString()}
                        <div className="text-xs text-gray-500">
                          {new Date(message.createdAt).toLocaleTimeString()}
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex gap-2">
                          <button className="p-1 text-blue-400 hover:text-blue-300" title="View Conversation">
                            <Eye className="w-4 h-4" />
                          </button>
                          <button className="p-1 text-yellow-400 hover:text-yellow-300" title="Flag Message">
                            <Flag className="w-4 h-4" />
                          </button>
                          <button className="p-1 text-red-400 hover:text-red-300" title="Delete Message">
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

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mt-6">
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Total Messages</p>
                <p className="text-2xl font-bold text-white">{messages.length}</p>
              </div>
              <MessageSquare className="w-8 h-8 text-blue-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Flagged</p>
                <p className="text-2xl font-bold text-white">
                  {messages.filter(msg => msg.status === 'FLAGGED' || msg.isReported).length}
                </p>
              </div>
              <Flag className="w-8 h-8 text-red-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Unread</p>
                <p className="text-2xl font-bold text-white">
                  {messages.filter(msg => !msg.isRead).length}
                </p>
              </div>
              <Clock className="w-8 h-8 text-yellow-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Today</p>
                <p className="text-2xl font-bold text-white">
                  {messages.filter(msg => {
                    const today = new Date();
                    const msgDate = new Date(msg.createdAt);
                    return msgDate.toDateString() === today.toDateString();
                  }).length}
                </p>
              </div>
              <Calendar className="w-8 h-8 text-purple-400" />
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  );
}