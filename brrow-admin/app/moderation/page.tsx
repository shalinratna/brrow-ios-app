'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  Shield,
  Search,
  Eye,
  CheckCircle,
  XCircle,
  Flag,
  AlertTriangle,
  User,
  Package,
  MessageSquare,
  Ban,
  Clock,
  Calendar,
  Filter
} from 'lucide-react';

interface ModerationItem {
  id: string;
  type: 'USER' | 'LISTING' | 'MESSAGE' | 'REPORT';
  status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'ESCALATED';
  priority: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  createdAt: string;
  reviewedAt?: string;
  reviewedBy?: string;
  content?: string;
  reason?: string;

  // Related entities
  user?: {
    id: string;
    email: string;
    username?: string;
    firstName?: string;
    lastName?: string;
    isActive: boolean;
    warningCount: number;
  };

  listing?: {
    id: string;
    title: string;
    price: number;
    status: string;
  };

  message?: {
    id: string;
    content: string;
    senderId: string;
    receiverId: string;
  };

  report?: {
    id: string;
    reason: string;
    description?: string;
    reportedBy: string;
    reportedAt: string;
  };

  violationType?: string;
  evidence?: Array<{
    type: 'IMAGE' | 'TEXT' | 'URL';
    content: string;
  }>;
}

export default function ModerationManagement() {
  const [moderationItems, setModerationItems] = useState<ModerationItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedItems, setSelectedItems] = useState<string[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [priorityFilter, setPriorityFilter] = useState('all');

  const fetchModerationItems = async () => {
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/moderation`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        setModerationItems(data.data?.items || data.items || []);
      } else {
        // Demo moderation data
        setModerationItems([
          {
            id: '1',
            type: 'USER',
            status: 'PENDING',
            priority: 'HIGH',
            createdAt: new Date().toISOString(),
            violationType: 'Spam/Scam',
            user: {
              id: 'user1',
              email: 'suspicious@example.com',
              username: 'suspicious_user',
              firstName: 'Suspicious',
              lastName: 'User',
              isActive: true,
              warningCount: 3
            },
            report: {
              id: 'report1',
              reason: 'Suspected fraudulent activity',
              description: 'User is posting fake listings and asking for payments outside the platform',
              reportedBy: 'user2',
              reportedAt: new Date(Date.now() - 3600000).toISOString()
            }
          },
          {
            id: '2',
            type: 'LISTING',
            status: 'PENDING',
            priority: 'MEDIUM',
            createdAt: new Date(Date.now() - 7200000).toISOString(),
            violationType: 'Inappropriate Content',
            listing: {
              id: 'listing1',
              title: 'Questionable Item for Sale',
              price: 999,
              status: 'FLAGGED'
            },
            report: {
              id: 'report2',
              reason: 'Inappropriate content',
              description: 'Listing contains inappropriate images and descriptions',
              reportedBy: 'user3',
              reportedAt: new Date(Date.now() - 3600000).toISOString()
            }
          },
          {
            id: '3',
            type: 'MESSAGE',
            status: 'ESCALATED',
            priority: 'CRITICAL',
            createdAt: new Date(Date.now() - 14400000).toISOString(),
            violationType: 'Harassment',
            message: {
              id: 'msg1',
              content: 'This message contains harassment and threatening language...',
              senderId: 'user4',
              receiverId: 'user5'
            },
            report: {
              id: 'report3',
              reason: 'Harassment and threats',
              description: 'User is sending threatening messages and harassment',
              reportedBy: 'user5',
              reportedAt: new Date(Date.now() - 10800000).toISOString()
            }
          },
          {
            id: '4',
            type: 'REPORT',
            status: 'APPROVED',
            priority: 'LOW',
            createdAt: new Date(Date.now() - 86400000).toISOString(),
            reviewedAt: new Date(Date.now() - 3600000).toISOString(),
            reviewedBy: 'admin1',
            violationType: 'Misleading Information',
            report: {
              id: 'report4',
              reason: 'False product description',
              description: 'Item description does not match the actual product',
              reportedBy: 'user6',
              reportedAt: new Date(Date.now() - 86400000).toISOString()
            }
          },
          {
            id: '5',
            type: 'USER',
            status: 'REJECTED',
            priority: 'LOW',
            createdAt: new Date(Date.now() - 172800000).toISOString(),
            reviewedAt: new Date(Date.now() - 86400000).toISOString(),
            reviewedBy: 'admin2',
            violationType: 'False Report',
            user: {
              id: 'user7',
              email: 'innocent@example.com',
              username: 'innocent_user',
              firstName: 'Innocent',
              lastName: 'User',
              isActive: true,
              warningCount: 0
            },
            report: {
              id: 'report5',
              reason: 'False accusation',
              description: 'Report was found to be false after investigation',
              reportedBy: 'user8',
              reportedAt: new Date(Date.now() - 172800000).toISOString()
            }
          }
        ]);
      }
    } catch (error) {
      console.error('Error fetching moderation items:', error);
      // Load demo data on error
      setModerationItems([
        {
          id: '1',
          type: 'USER',
          status: 'PENDING',
          priority: 'HIGH',
          createdAt: new Date().toISOString(),
          violationType: 'Spam',
          user: {
            id: 'user1',
            email: 'test@example.com',
            username: 'testuser',
            firstName: 'Test',
            lastName: 'User',
            isActive: true,
            warningCount: 1
          }
        }
      ]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchModerationItems();
  }, []);

  const handleBulkAction = async (action: 'approve' | 'reject' | 'escalate' | 'ban') => {
    if (selectedItems.length === 0) return;

    const confirmAction = confirm(`Are you sure you want to ${action} ${selectedItems.length} items?`);
    if (!confirmAction) return;

    try {
      for (const itemId of selectedItems) {
        await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/moderation/${itemId}`, {
          method: 'PATCH',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            action,
            reviewedBy: 'current_admin',
            reviewedAt: new Date().toISOString()
          })
        });
      }

      setSelectedItems([]);
      fetchModerationItems();
    } catch (error) {
      console.error(`Error performing ${action}:`, error);
    }
  };

  const filteredItems = moderationItems.filter(item => {
    const matchesSearch =
      item.user?.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.listing?.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.violationType?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.report?.reason.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = statusFilter === 'all' || item.status === statusFilter;
    const matchesType = typeFilter === 'all' || item.type === typeFilter;
    const matchesPriority = priorityFilter === 'all' || item.priority === priorityFilter;

    return matchesSearch && matchesStatus && matchesType && matchesPriority;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'PENDING': return 'bg-yellow-100 text-yellow-800';
      case 'APPROVED': return 'bg-green-100 text-green-800';
      case 'REJECTED': return 'bg-red-100 text-red-800';
      case 'ESCALATED': return 'bg-purple-100 text-purple-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'CRITICAL': return 'bg-red-100 text-red-800';
      case 'HIGH': return 'bg-orange-100 text-orange-800';
      case 'MEDIUM': return 'bg-yellow-100 text-yellow-800';
      case 'LOW': return 'bg-green-100 text-green-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'USER': return User;
      case 'LISTING': return Package;
      case 'MESSAGE': return MessageSquare;
      case 'REPORT': return Flag;
      default: return AlertTriangle;
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
              Moderation Center
            </h1>
            <p className="text-gray-400 mt-2">Review and moderate platform content and user reports</p>
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
                placeholder="Search moderation items..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* Filters */}
            <div className="flex gap-2 flex-wrap">
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">All Status</option>
                <option value="PENDING">Pending</option>
                <option value="APPROVED">Approved</option>
                <option value="REJECTED">Rejected</option>
                <option value="ESCALATED">Escalated</option>
              </select>

              <select
                value={typeFilter}
                onChange={(e) => setTypeFilter(e.target.value)}
                className="px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">All Types</option>
                <option value="USER">Users</option>
                <option value="LISTING">Listings</option>
                <option value="MESSAGE">Messages</option>
                <option value="REPORT">Reports</option>
              </select>

              <select
                value={priorityFilter}
                onChange={(e) => setPriorityFilter(e.target.value)}
                className="px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">All Priority</option>
                <option value="CRITICAL">Critical</option>
                <option value="HIGH">High</option>
                <option value="MEDIUM">Medium</option>
                <option value="LOW">Low</option>
              </select>
            </div>

            {/* Bulk Actions */}
            {selectedItems.length > 0 && (
              <div className="flex gap-2">
                <button
                  onClick={() => handleBulkAction('approve')}
                  className="px-3 py-1 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm"
                >
                  Approve ({selectedItems.length})
                </button>
                <button
                  onClick={() => handleBulkAction('reject')}
                  className="px-3 py-1 bg-red-600 text-white rounded-lg hover:bg-red-700 text-sm"
                >
                  Reject ({selectedItems.length})
                </button>
                <button
                  onClick={() => handleBulkAction('escalate')}
                  className="px-3 py-1 bg-purple-600 text-white rounded-lg hover:bg-purple-700 text-sm"
                >
                  Escalate ({selectedItems.length})
                </button>
                <button
                  onClick={() => handleBulkAction('ban')}
                  className="px-3 py-1 bg-gray-600 text-white rounded-lg hover:bg-gray-700 text-sm"
                >
                  Ban ({selectedItems.length})
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Moderation Items Table */}
        <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl overflow-hidden">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
              <span className="ml-3 text-gray-400">Loading moderation items...</span>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-800/50">
                  <tr>
                    <th className="p-4 text-left">
                      <input
                        type="checkbox"
                        checked={selectedItems.length === filteredItems.length && filteredItems.length > 0}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedItems(filteredItems.map(item => item.id));
                          } else {
                            setSelectedItems([]);
                          }
                        }}
                        className="rounded border-gray-600 bg-gray-700 text-blue-600"
                      />
                    </th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Item</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Type</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Priority</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Status</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Report</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Created</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredItems.map((item) => {
                    const TypeIcon = getTypeIcon(item.type);

                    return (
                      <tr key={item.id} className="border-t border-gray-800 hover:bg-gray-800/30">
                        <td className="p-4">
                          <input
                            type="checkbox"
                            checked={selectedItems.includes(item.id)}
                            onChange={(e) => {
                              if (e.target.checked) {
                                setSelectedItems([...selectedItems, item.id]);
                              } else {
                                setSelectedItems(selectedItems.filter(id => id !== item.id));
                              }
                            }}
                            className="rounded border-gray-600 bg-gray-700 text-blue-600"
                          />
                        </td>
                        <td className="p-4">
                          <div className="flex items-start gap-3">
                            <TypeIcon className="w-5 h-5 text-gray-400 mt-1 flex-shrink-0" />
                            <div>
                              <div className="font-medium text-white">
                                {item.violationType || 'Moderation Required'}
                              </div>
                              <div className="text-sm text-gray-400">
                                {item.user && `User: ${item.user.email}`}
                                {item.listing && `Listing: ${item.listing.title}`}
                                {item.message && 'Message Content'}
                                {item.report && !item.user && !item.listing && !item.message && 'General Report'}
                              </div>
                              {item.user?.warningCount > 0 && (
                                <div className="text-xs text-orange-400 mt-1">
                                  {item.user.warningCount} previous warnings
                                </div>
                              )}
                            </div>
                          </div>
                        </td>
                        <td className="p-4">
                          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                            {item.type}
                          </span>
                        </td>
                        <td className="p-4">
                          <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getPriorityColor(item.priority)}`}>
                            {item.priority}
                          </span>
                        </td>
                        <td className="p-4">
                          <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(item.status)}`}>
                            {item.status === 'PENDING' && <Clock className="w-3 h-3 mr-1" />}
                            {item.status === 'APPROVED' && <CheckCircle className="w-3 h-3 mr-1" />}
                            {item.status === 'REJECTED' && <XCircle className="w-3 h-3 mr-1" />}
                            {item.status === 'ESCALATED' && <AlertTriangle className="w-3 h-3 mr-1" />}
                            {item.status}
                          </span>
                        </td>
                        <td className="p-4 max-w-xs">
                          {item.report && (
                            <div>
                              <div className="text-sm text-white font-medium mb-1">
                                {item.report.reason}
                              </div>
                              {item.report.description && (
                                <div className="text-xs text-gray-400">
                                  {item.report.description.length > 80
                                    ? `${item.report.description.substring(0, 80)}...`
                                    : item.report.description
                                  }
                                </div>
                              )}
                            </div>
                          )}
                        </td>
                        <td className="p-4 text-sm text-gray-400">
                          {new Date(item.createdAt).toLocaleDateString()}
                          <div className="text-xs text-gray-500">
                            {new Date(item.createdAt).toLocaleTimeString()}
                          </div>
                          {item.reviewedAt && (
                            <div className="text-xs text-blue-400 mt-1">
                              Reviewed by {item.reviewedBy}
                            </div>
                          )}
                        </td>
                        <td className="p-4">
                          <div className="flex gap-2">
                            <button className="p-1 text-blue-400 hover:text-blue-300" title="View Details">
                              <Eye className="w-4 h-4" />
                            </button>
                            {item.status === 'PENDING' && (
                              <>
                                <button className="p-1 text-green-400 hover:text-green-300" title="Approve">
                                  <CheckCircle className="w-4 h-4" />
                                </button>
                                <button className="p-1 text-red-400 hover:text-red-300" title="Reject">
                                  <XCircle className="w-4 h-4" />
                                </button>
                                <button className="p-1 text-purple-400 hover:text-purple-300" title="Escalate">
                                  <AlertTriangle className="w-4 h-4" />
                                </button>
                              </>
                            )}
                            <button className="p-1 text-gray-400 hover:text-gray-300" title="Ban User">
                              <Ban className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
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
                <p className="text-sm text-gray-400">Pending Review</p>
                <p className="text-2xl font-bold text-white">
                  {moderationItems.filter(item => item.status === 'PENDING').length}
                </p>
              </div>
              <Clock className="w-8 h-8 text-yellow-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Critical Priority</p>
                <p className="text-2xl font-bold text-white">
                  {moderationItems.filter(item => item.priority === 'CRITICAL').length}
                </p>
              </div>
              <AlertTriangle className="w-8 h-8 text-red-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Escalated</p>
                <p className="text-2xl font-bold text-white">
                  {moderationItems.filter(item => item.status === 'ESCALATED').length}
                </p>
              </div>
              <Flag className="w-8 h-8 text-purple-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Resolved Today</p>
                <p className="text-2xl font-bold text-white">
                  {moderationItems.filter(item => {
                    const today = new Date();
                    const reviewDate = item.reviewedAt ? new Date(item.reviewedAt) : null;
                    return reviewDate && reviewDate.toDateString() === today.toDateString();
                  }).length}
                </p>
              </div>
              <Calendar className="w-8 h-8 text-green-400" />
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  );
}