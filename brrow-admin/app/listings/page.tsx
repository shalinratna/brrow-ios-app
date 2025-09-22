'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  Package,
  Search,
  Edit,
  Trash2,
  Eye,
  CheckCircle,
  XCircle,
  DollarSign,
  Calendar,
  User,
  Filter
} from 'lucide-react';

interface Listing {
  id: string;
  title: string;
  description?: string;
  price: number;
  availabilityStatus: string;
  createdAt: string;
  user?: {
    id: string;
    email: string;
    username?: string;
    firstName?: string;
    lastName?: string;
  };
  images?: Array<{
    imageUrl: string;
    isPrimary: boolean;
  }>;
  category?: {
    name: string;
  };
  _count?: {
    favorites: number;
  };
}

export default function ListingsManagement() {
  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedListings, setSelectedListings] = useState<string[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [error, setError] = useState<string | null>(null);

  const fetchListings = async () => {
    setLoading(true);
    setError(null);

    try {
      const adminToken = localStorage.getItem('adminToken');
      if (!adminToken) {
        setError('No admin token found. Please log in again.');
        setLoading(false);
        return;
      }

      // Fetch real listings from your Railway backend
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/listings`, {
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
      console.log('Listings API Response:', data);

      if (data.success && data.data && data.data.listings) {
        setListings(data.data.listings);
        console.log(`Loaded ${data.data.listings.length} real listings from database`);
      } else if (Array.isArray(data)) {
        setListings(data);
        console.log(`Loaded ${data.length} real listings from database`);
      } else {
        setError('No listings data received from API');
      }

    } catch (error) {
      console.error('Error fetching listings:', error);
      setError('Failed to connect to backend server');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchListings();
  }, []);

  const handleBulkAction = async (action: 'approve' | 'reject' | 'delete') => {
    if (selectedListings.length === 0) return;

    const confirmAction = confirm(`Are you sure you want to ${action} ${selectedListings.length} listings?`);
    if (!confirmAction) return;

    try {
      const adminToken = localStorage.getItem('adminToken');

      for (const listingId of selectedListings) {
        if (action === 'delete') {
          await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/listings/${listingId}`, {
            method: 'DELETE',
            headers: {
              'Authorization': `Bearer ${adminToken}`,
              'Content-Type': 'application/json'
            }
          });
        } else {
          await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/listings/${listingId}/moderate`, {
            method: 'PATCH',
            headers: {
              'Authorization': `Bearer ${adminToken}`,
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({
              status: action === 'approve' ? 'AVAILABLE' : 'REMOVED',
              reason: action === 'reject' ? 'Administrative action' : undefined
            })
          });
        }
      }

      setSelectedListings([]);
      fetchListings(); // Reload real data
    } catch (error) {
      console.error(`Error performing ${action}:`, error);
    }
  };

  const filteredListings = listings.filter(listing => {
    const matchesSearch = listing.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         listing.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         listing.user?.email.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = statusFilter === 'all' || listing.availabilityStatus === statusFilter;

    return matchesSearch && matchesStatus;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'AVAILABLE': return 'bg-green-100 text-green-800';
      case 'RENTED': return 'bg-blue-100 text-blue-800';
      case 'PENDING': return 'bg-yellow-100 text-yellow-800';
      case 'REMOVED': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950 p-6">
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="flex items-center gap-3">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
            <span className="text-gray-400">Loading real listings from database...</span>
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
              onClick={fetchListings}
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
              Listings Management
            </h1>
            <p className="text-gray-400 mt-2">
              Manage all platform listings • {listings.length} total listings from database
            </p>
          </div>
          <button
            onClick={fetchListings}
            className="px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white hover:bg-gray-700 flex items-center gap-2"
          >
            <Eye className="w-4 h-4" />
            Refresh
          </button>
        </div>

        {/* Controls */}
        <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6 mb-6">
          <div className="flex flex-col lg:flex-row gap-4 items-center justify-between">
            {/* Search */}
            <div className="relative flex-1 max-w-md">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
              <input
                type="text"
                placeholder="Search listings..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* Status Filter */}
            <div className="flex gap-2">
              {['all', 'AVAILABLE', 'RENTED', 'PENDING', 'REMOVED'].map((status) => (
                <button
                  key={status}
                  onClick={() => setStatusFilter(status)}
                  className={`px-3 py-1 rounded-lg text-sm font-medium transition-all ${
                    statusFilter === status
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
                  }`}
                >
                  {status === 'all' ? 'All' : status}
                </button>
              ))}
            </div>

            {/* Bulk Actions */}
            {selectedListings.length > 0 && (
              <div className="flex gap-2">
                <button
                  onClick={() => handleBulkAction('approve')}
                  className="px-3 py-1 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm"
                >
                  Approve ({selectedListings.length})
                </button>
                <button
                  onClick={() => handleBulkAction('reject')}
                  className="px-3 py-1 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 text-sm"
                >
                  Reject ({selectedListings.length})
                </button>
                <button
                  onClick={() => handleBulkAction('delete')}
                  className="px-3 py-1 bg-red-600 text-white rounded-lg hover:bg-red-700 text-sm"
                >
                  Delete ({selectedListings.length})
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Listings Table */}
        <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl overflow-hidden">
          {filteredListings.length === 0 && !loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="text-center">
                <div className="text-gray-400 text-lg">No listings found</div>
                <div className="text-gray-500 text-sm mt-2">
                  {listings.length === 0 ? 'No listings in database' : 'Try adjusting your search or filters'}
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
                        checked={selectedListings.length === filteredListings.length && filteredListings.length > 0}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedListings(filteredListings.map(l => l.id));
                          } else {
                            setSelectedListings([]);
                          }
                        }}
                        className="rounded border-gray-600 bg-gray-700 text-blue-600"
                      />
                    </th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Listing</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Price</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Status</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Owner</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Created</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredListings.map((listing) => (
                    <tr key={listing.id} className="border-t border-gray-800 hover:bg-gray-800/30">
                      <td className="p-4">
                        <input
                          type="checkbox"
                          checked={selectedListings.includes(listing.id)}
                          onChange={(e) => {
                            if (e.target.checked) {
                              setSelectedListings([...selectedListings, listing.id]);
                            } else {
                              setSelectedListings(selectedListings.filter(id => id !== listing.id));
                            }
                          }}
                          className="rounded border-gray-600 bg-gray-700 text-blue-600"
                        />
                      </td>
                      <td className="p-4">
                        <div className="flex items-start gap-3">
                          {listing.images && listing.images.length > 0 && (
                            <img
                              src={listing.images.find(img => img.isPrimary)?.imageUrl || listing.images[0].imageUrl}
                              alt={listing.title}
                              className="w-12 h-12 object-cover rounded-lg"
                            />
                          )}
                          <div>
                            <div className="font-medium text-white">{listing.title}</div>
                            <div className="text-sm text-gray-400 truncate max-w-xs">
                              {listing.description}
                            </div>
                            <div className="text-xs text-gray-500">
                              {listing.category?.name} • {listing._count?.favorites || 0} favorites
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center text-green-400 font-medium">
                          <DollarSign className="w-4 h-4 mr-1" />
                          {listing.price}
                        </div>
                      </td>
                      <td className="p-4">
                        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(listing.availabilityStatus)}`}>
                          {listing.availabilityStatus === 'AVAILABLE' && <CheckCircle className="w-3 h-3 mr-1" />}
                          {listing.availabilityStatus === 'REMOVED' && <XCircle className="w-3 h-3 mr-1" />}
                          {listing.availabilityStatus}
                        </span>
                      </td>
                      <td className="p-4">
                        <div>
                          <div className="text-sm text-white">
                            {listing.user?.firstName && listing.user?.lastName
                              ? `${listing.user.firstName} ${listing.user.lastName}`
                              : listing.user?.username || 'Unknown'
                            }
                          </div>
                          <div className="text-xs text-gray-400">{listing.user?.email}</div>
                        </div>
                      </td>
                      <td className="p-4 text-sm text-gray-400">
                        {new Date(listing.createdAt).toLocaleDateString()}
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

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mt-6">
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Total Listings</p>
                <p className="text-2xl font-bold text-white">{listings.length}</p>
              </div>
              <Package className="w-8 h-8 text-blue-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Available</p>
                <p className="text-2xl font-bold text-white">
                  {listings.filter(l => l.availabilityStatus === 'AVAILABLE').length}
                </p>
              </div>
              <CheckCircle className="w-8 h-8 text-green-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Total Value</p>
                <p className="text-2xl font-bold text-white">
                  ${listings.reduce((sum, l) => sum + l.price, 0).toLocaleString()}
                </p>
              </div>
              <DollarSign className="w-8 h-8 text-green-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">New Today</p>
                <p className="text-2xl font-bold text-white">
                  {listings.filter(l => {
                    const today = new Date();
                    const listingDate = new Date(l.createdAt);
                    return listingDate.toDateString() === today.toDateString();
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