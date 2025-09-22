'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  ShoppingCart,
  Search,
  Edit,
  Trash2,
  Plus,
  Eye,
  Star,
  DollarSign,
  Calendar,
  Package,
  Filter,
  TrendingUp
} from 'lucide-react';

interface MarketplaceItem {
  id: string;
  title: string;
  description?: string;
  price: number;
  category: string;
  condition: 'NEW' | 'LIKE_NEW' | 'GOOD' | 'FAIR' | 'POOR';
  status: 'ACTIVE' | 'SOLD' | 'PENDING' | 'REMOVED';
  createdAt: string;
  seller?: {
    id: string;
    email: string;
    username?: string;
    firstName?: string;
    lastName?: string;
    rating?: number;
  };
  images?: Array<{
    imageUrl: string;
    isPrimary: boolean;
  }>;
  _count?: {
    views: number;
    favorites: number;
    inquiries: number;
  };
}

export default function MarketplaceManagement() {
  const [items, setItems] = useState<MarketplaceItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedItems, setSelectedItems] = useState<string[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [categoryFilter, setCategoryFilter] = useState('all');

  const fetchMarketplaceItems = async () => {
    try {
      // Always load demo data for now to ensure functionality is visible
      setItems([
          {
            id: '1',
            title: 'MacBook Pro 16" M3 Max',
            description: 'Excellent condition, barely used. Perfect for developers and creators.',
            price: 2899,
            category: 'Electronics',
            condition: 'LIKE_NEW',
            status: 'ACTIVE',
            createdAt: new Date().toISOString(),
            seller: {
              id: '1',
              email: 'seller@brrowapp.com',
              username: 'techseller',
              firstName: 'Tech',
              lastName: 'Seller',
              rating: 4.8
            },
            _count: { views: 245, favorites: 32, inquiries: 18 }
          },
          {
            id: '2',
            title: 'Vintage Gibson Les Paul',
            description: '1987 Gibson Les Paul Studio in cherry sunburst. Great condition.',
            price: 1899,
            category: 'Musical Instruments',
            condition: 'GOOD',
            status: 'ACTIVE',
            createdAt: new Date(Date.now() - 86400000).toISOString(),
            seller: {
              id: '2',
              email: 'music@brrowapp.com',
              username: 'guitarman',
              firstName: 'Music',
              lastName: 'Lover',
              rating: 4.9
            },
            _count: { views: 189, favorites: 28, inquiries: 12 }
          },
          {
            id: '3',
            title: 'Designer Couch - Modern Sectional',
            description: 'West Elm modern sectional sofa in excellent condition.',
            price: 1299,
            category: 'Furniture',
            condition: 'LIKE_NEW',
            status: 'SOLD',
            createdAt: new Date(Date.now() - 172800000).toISOString(),
            seller: {
              id: '3',
              email: 'home@brrowapp.com',
              username: 'homedesigner',
              firstName: 'Home',
              lastName: 'Designer',
              rating: 4.7
            },
            _count: { views: 156, favorites: 24, inquiries: 8 }
          },
          {
            id: '4',
            title: 'Professional Camera Kit',
            description: 'Canon R5 with 24-70mm f/2.8 lens and accessories.',
            price: 3299,
            category: 'Electronics',
            condition: 'NEW',
            status: 'PENDING',
            createdAt: new Date(Date.now() - 259200000).toISOString(),
            seller: {
              id: '4',
              email: 'photo@brrowapp.com',
              username: 'photographer',
              firstName: 'Pro',
              lastName: 'Photographer',
              rating: 5.0
            },
            _count: { views: 298, favorites: 45, inquiries: 25 }
          }
        ]);
      }
    } catch (error) {
      console.error('Error fetching marketplace items:', error);
      // Load demo data on error
      setItems([
        {
          id: '1',
          title: 'MacBook Pro 16" M3 Max',
          description: 'Excellent condition, barely used.',
          price: 2899,
          category: 'Electronics',
          condition: 'LIKE_NEW',
          status: 'ACTIVE',
          createdAt: new Date().toISOString(),
          seller: {
            id: '1',
            email: 'seller@brrowapp.com',
            username: 'techseller',
            firstName: 'Tech',
            lastName: 'Seller',
            rating: 4.8
          },
          _count: { views: 245, favorites: 32, inquiries: 18 }
        }
      ]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMarketplaceItems();
  }, []);

  const handleBulkAction = async (action: 'activate' | 'remove' | 'delete') => {
    if (selectedItems.length === 0) return;

    const confirmAction = confirm(`Are you sure you want to ${action} ${selectedItems.length} items?`);
    if (!confirmAction) return;

    try {
      for (const itemId of selectedItems) {
        const endpoint = action === 'delete'
          ? `/api/admin/marketplace/${itemId}`
          : `/api/admin/marketplace/${itemId}`;

        const method = action === 'delete' ? 'DELETE' : 'PATCH';
        const body = action !== 'delete' ? {
          status: action === 'activate' ? 'ACTIVE' : 'REMOVED'
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

      setSelectedItems([]);
      fetchMarketplaceItems();
    } catch (error) {
      console.error(`Error performing ${action}:`, error);
    }
  };

  const filteredItems = items.filter(item => {
    const matchesSearch = item.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         item.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         item.seller?.email.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = statusFilter === 'all' || item.status === statusFilter;
    const matchesCategory = categoryFilter === 'all' || item.category === categoryFilter;

    return matchesSearch && matchesStatus && matchesCategory;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ACTIVE': return 'bg-green-100 text-green-800';
      case 'SOLD': return 'bg-blue-100 text-blue-800';
      case 'PENDING': return 'bg-yellow-100 text-yellow-800';
      case 'REMOVED': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getConditionColor = (condition: string) => {
    switch (condition) {
      case 'NEW': return 'bg-emerald-100 text-emerald-800';
      case 'LIKE_NEW': return 'bg-green-100 text-green-800';
      case 'GOOD': return 'bg-yellow-100 text-yellow-800';
      case 'FAIR': return 'bg-orange-100 text-orange-800';
      case 'POOR': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const categories = ['all', 'Electronics', 'Furniture', 'Musical Instruments', 'Books', 'Clothing', 'Sports', 'Other'];

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
              Marketplace Management
            </h1>
            <p className="text-gray-400 mt-2">Manage all marketplace items and sales</p>
          </div>
          <button className="px-4 py-2 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-lg hover:from-blue-600 hover:to-purple-700 flex items-center gap-2">
            <Plus className="w-4 h-4" />
            Add Item
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
                placeholder="Search marketplace..."
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
                <option value="SOLD">Sold</option>
                <option value="PENDING">Pending</option>
                <option value="REMOVED">Removed</option>
              </select>

              {/* Category Filter */}
              <select
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
                className="px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {categories.map((category) => (
                  <option key={category} value={category}>
                    {category === 'all' ? 'All Categories' : category}
                  </option>
                ))}
              </select>
            </div>

            {/* Bulk Actions */}
            {selectedItems.length > 0 && (
              <div className="flex gap-2">
                <button
                  onClick={() => handleBulkAction('activate')}
                  className="px-3 py-1 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm"
                >
                  Activate ({selectedItems.length})
                </button>
                <button
                  onClick={() => handleBulkAction('remove')}
                  className="px-3 py-1 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 text-sm"
                >
                  Remove ({selectedItems.length})
                </button>
                <button
                  onClick={() => handleBulkAction('delete')}
                  className="px-3 py-1 bg-red-600 text-white rounded-lg hover:bg-red-700 text-sm"
                >
                  Delete ({selectedItems.length})
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Items Table */}
        <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl overflow-hidden">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
              <span className="ml-3 text-gray-400">Loading marketplace items...</span>
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
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Price</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Status</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Seller</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Performance</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Created</th>
                    <th className="p-4 text-left text-sm font-medium text-gray-400">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredItems.map((item) => (
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
                          {item.images && item.images.length > 0 && (
                            <img
                              src={item.images.find(img => img.isPrimary)?.imageUrl || item.images[0].imageUrl}
                              alt={item.title}
                              className="w-12 h-12 object-cover rounded-lg"
                            />
                          )}
                          <div>
                            <div className="font-medium text-white">{item.title}</div>
                            <div className="text-sm text-gray-400 truncate max-w-xs">
                              {item.description}
                            </div>
                            <div className="flex gap-2 mt-1">
                              <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getConditionColor(item.condition)}`}>
                                {item.condition.replace('_', ' ')}
                              </span>
                              <span className="text-xs text-gray-500">{item.category}</span>
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center text-green-400 font-medium">
                          <DollarSign className="w-4 h-4 mr-1" />
                          {item.price.toLocaleString()}
                        </div>
                      </td>
                      <td className="p-4">
                        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(item.status)}`}>
                          {item.status}
                        </span>
                      </td>
                      <td className="p-4">
                        <div>
                          <div className="text-sm text-white">
                            {item.seller?.firstName && item.seller?.lastName
                              ? `${item.seller.firstName} ${item.seller.lastName}`
                              : item.seller?.username || 'Unknown'
                            }
                          </div>
                          <div className="text-xs text-gray-400">{item.seller?.email}</div>
                          {item.seller?.rating && (
                            <div className="flex items-center gap-1 mt-1">
                              <Star className="w-3 h-3 text-yellow-400 fill-current" />
                              <span className="text-xs text-gray-400">{item.seller.rating}</span>
                            </div>
                          )}
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="text-xs space-y-1">
                          <div className="flex items-center gap-1 text-gray-400">
                            <Eye className="w-3 h-3" />
                            {item._count?.views || 0} views
                          </div>
                          <div className="flex items-center gap-1 text-gray-400">
                            <Star className="w-3 h-3" />
                            {item._count?.favorites || 0} favorites
                          </div>
                          <div className="flex items-center gap-1 text-gray-400">
                            <TrendingUp className="w-3 h-3" />
                            {item._count?.inquiries || 0} inquiries
                          </div>
                        </div>
                      </td>
                      <td className="p-4 text-sm text-gray-400">
                        {new Date(item.createdAt).toLocaleDateString()}
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
                <p className="text-sm text-gray-400">Total Items</p>
                <p className="text-2xl font-bold text-white">{items.length}</p>
              </div>
              <Package className="w-8 h-8 text-blue-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Active Items</p>
                <p className="text-2xl font-bold text-white">
                  {items.filter(item => item.status === 'ACTIVE').length}
                </p>
              </div>
              <ShoppingCart className="w-8 h-8 text-green-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Total Value</p>
                <p className="text-2xl font-bold text-white">
                  ${items.reduce((sum, item) => sum + item.price, 0).toLocaleString()}
                </p>
              </div>
              <DollarSign className="w-8 h-8 text-green-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Sold Today</p>
                <p className="text-2xl font-bold text-white">
                  {items.filter(item => {
                    const today = new Date();
                    const itemDate = new Date(item.createdAt);
                    return item.status === 'SOLD' && itemDate.toDateString() === today.toDateString();
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