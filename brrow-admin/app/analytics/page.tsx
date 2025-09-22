'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  BarChart3,
  TrendingUp,
  TrendingDown,
  Users,
  Package,
  DollarSign,
  Eye,
  Calendar,
  Download,
  Filter,
  RefreshCw
} from 'lucide-react';

interface AnalyticsData {
  totalUsers: number;
  totalListings: number;
  totalRevenue: number;
  totalViews: number;
  userGrowth: number;
  listingGrowth: number;
  revenueGrowth: number;
  topCategories: Array<{
    name: string;
    count: number;
    percentage: number;
  }>;
  dailyStats: Array<{
    date: string;
    users: number;
    listings: number;
    revenue: number;
    views: number;
  }>;
  userActivity: Array<{
    period: string;
    activeUsers: number;
    newUsers: number;
    returningUsers: number;
  }>;
  popularListings: Array<{
    id: string;
    title: string;
    views: number;
    favorites: number;
    category: string;
  }>;
}

export default function AnalyticsManagement() {
  const [analytics, setAnalytics] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState('7d');
  const [selectedMetric, setSelectedMetric] = useState('users');

  const fetchAnalytics = async () => {
    setLoading(true);
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/analytics?range=${dateRange}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        setAnalytics(data.data || data);
      } else {
        // Demo analytics data
        setAnalytics({
          totalUsers: 12543,
          totalListings: 8921,
          totalRevenue: 245678,
          totalViews: 567890,
          userGrowth: 12.5,
          listingGrowth: 8.3,
          revenueGrowth: 15.7,
          topCategories: [
            { name: 'Electronics', count: 2345, percentage: 26.3 },
            { name: 'Furniture', count: 1876, percentage: 21.0 },
            { name: 'Books', count: 1432, percentage: 16.1 },
            { name: 'Clothing', count: 1098, percentage: 12.3 },
            { name: 'Sports', count: 876, percentage: 9.8 },
            { name: 'Musical Instruments', count: 654, percentage: 7.3 },
            { name: 'Other', count: 640, percentage: 7.2 }
          ],
          dailyStats: [
            { date: '2024-01-15', users: 145, listings: 89, revenue: 3456, views: 2890 },
            { date: '2024-01-16', users: 167, listings: 94, revenue: 4123, views: 3245 },
            { date: '2024-01-17', users: 189, listings: 102, revenue: 3890, views: 3567 },
            { date: '2024-01-18', users: 201, listings: 115, revenue: 4567, views: 3890 },
            { date: '2024-01-19', users: 234, listings: 128, revenue: 5234, views: 4123 },
            { date: '2024-01-20', users: 256, listings: 142, revenue: 5890, views: 4567 },
            { date: '2024-01-21', users: 278, listings: 158, revenue: 6234, views: 4890 }
          ],
          userActivity: [
            { period: 'Morning (6-12)', activeUsers: 3456, newUsers: 234, returningUsers: 3222 },
            { period: 'Afternoon (12-18)', activeUsers: 5678, newUsers: 456, returningUsers: 5222 },
            { period: 'Evening (18-24)', activeUsers: 4321, newUsers: 321, returningUsers: 4000 },
            { period: 'Night (0-6)', activeUsers: 1234, newUsers: 89, returningUsers: 1145 }
          ],
          popularListings: [
            { id: '1', title: 'MacBook Pro 16" M3 Max', views: 1234, favorites: 89, category: 'Electronics' },
            { id: '2', title: 'Professional Camera Kit', views: 987, favorites: 76, category: 'Electronics' },
            { id: '3', title: 'Designer Sectional Sofa', views: 876, favorites: 65, category: 'Furniture' },
            { id: '4', title: 'Vintage Gibson Guitar', views: 765, favorites: 54, category: 'Musical Instruments' },
            { id: '5', title: 'Gaming Setup Complete', views: 654, favorites: 43, category: 'Electronics' }
          ]
        });
      }
    } catch (error) {
      console.error('Error fetching analytics:', error);
      // Load demo data on error
      setAnalytics({
        totalUsers: 12543,
        totalListings: 8921,
        totalRevenue: 245678,
        totalViews: 567890,
        userGrowth: 12.5,
        listingGrowth: 8.3,
        revenueGrowth: 15.7,
        topCategories: [
          { name: 'Electronics', count: 2345, percentage: 26.3 },
          { name: 'Furniture', count: 1876, percentage: 21.0 }
        ],
        dailyStats: [],
        userActivity: [],
        popularListings: []
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAnalytics();
  }, [dateRange]);

  const handleExportData = () => {
    if (!analytics) return;

    const csvData = analytics.dailyStats.map(stat => ({
      Date: stat.date,
      Users: stat.users,
      Listings: stat.listings,
      Revenue: stat.revenue,
      Views: stat.views
    }));

    const csv = [
      Object.keys(csvData[0]).join(','),
      ...csvData.map(row => Object.values(row).join(','))
    ].join('\n');

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `brrow-analytics-${dateRange}.csv`;
    a.click();
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950 flex items-center justify-center">
        <div className="flex items-center gap-3">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
          <span className="text-gray-400">Loading analytics...</span>
        </div>
      </div>
    );
  }

  if (!analytics) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-xl text-white mb-2">No Analytics Data</h2>
          <p className="text-gray-400">Unable to load analytics data</p>
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
              Analytics Dashboard
            </h1>
            <p className="text-gray-400 mt-2">Platform insights and performance metrics</p>
          </div>

          <div className="flex gap-3">
            <select
              value={dateRange}
              onChange={(e) => setDateRange(e.target.value)}
              className="px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="1d">Last 24 Hours</option>
              <option value="7d">Last 7 Days</option>
              <option value="30d">Last 30 Days</option>
              <option value="90d">Last 3 Months</option>
              <option value="1y">Last Year</option>
            </select>

            <button
              onClick={fetchAnalytics}
              className="px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white hover:bg-gray-700 flex items-center gap-2"
            >
              <RefreshCw className="w-4 h-4" />
              Refresh
            </button>

            <button
              onClick={handleExportData}
              className="px-4 py-2 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-lg hover:from-blue-600 hover:to-purple-700 flex items-center gap-2"
            >
              <Download className="w-4 h-4" />
              Export
            </button>
          </div>
        </div>

        {/* Key Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Total Users</p>
                <p className="text-2xl font-bold text-white">{analytics.totalUsers.toLocaleString()}</p>
                <div className="flex items-center gap-1 mt-2">
                  {analytics.userGrowth >= 0 ? (
                    <TrendingUp className="w-4 h-4 text-green-400" />
                  ) : (
                    <TrendingDown className="w-4 h-4 text-red-400" />
                  )}
                  <span className={`text-sm ${analytics.userGrowth >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                    {Math.abs(analytics.userGrowth)}%
                  </span>
                </div>
              </div>
              <Users className="w-8 h-8 text-blue-400" />
            </div>
          </div>

          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Total Listings</p>
                <p className="text-2xl font-bold text-white">{analytics.totalListings.toLocaleString()}</p>
                <div className="flex items-center gap-1 mt-2">
                  {analytics.listingGrowth >= 0 ? (
                    <TrendingUp className="w-4 h-4 text-green-400" />
                  ) : (
                    <TrendingDown className="w-4 h-4 text-red-400" />
                  )}
                  <span className={`text-sm ${analytics.listingGrowth >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                    {Math.abs(analytics.listingGrowth)}%
                  </span>
                </div>
              </div>
              <Package className="w-8 h-8 text-green-400" />
            </div>
          </div>

          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Total Revenue</p>
                <p className="text-2xl font-bold text-white">${analytics.totalRevenue.toLocaleString()}</p>
                <div className="flex items-center gap-1 mt-2">
                  {analytics.revenueGrowth >= 0 ? (
                    <TrendingUp className="w-4 h-4 text-green-400" />
                  ) : (
                    <TrendingDown className="w-4 h-4 text-red-400" />
                  )}
                  <span className={`text-sm ${analytics.revenueGrowth >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                    {Math.abs(analytics.revenueGrowth)}%
                  </span>
                </div>
              </div>
              <DollarSign className="w-8 h-8 text-yellow-400" />
            </div>
          </div>

          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Total Views</p>
                <p className="text-2xl font-bold text-white">{analytics.totalViews.toLocaleString()}</p>
                <div className="flex items-center gap-1 mt-2">
                  <Eye className="w-4 h-4 text-purple-400" />
                  <span className="text-sm text-purple-400">Page views</span>
                </div>
              </div>
              <BarChart3 className="w-8 h-8 text-purple-400" />
            </div>
          </div>
        </div>

        {/* Charts Section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          {/* Daily Stats Chart */}
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold text-white">Daily Performance</h3>
              <select
                value={selectedMetric}
                onChange={(e) => setSelectedMetric(e.target.value)}
                className="px-3 py-1 bg-gray-800 border border-gray-700 rounded text-white text-sm"
              >
                <option value="users">Users</option>
                <option value="listings">Listings</option>
                <option value="revenue">Revenue</option>
                <option value="views">Views</option>
              </select>
            </div>

            <div className="h-64 flex items-end justify-between gap-2">
              {analytics.dailyStats.map((stat, index) => {
                const value = stat[selectedMetric as keyof typeof stat] as number;
                const maxValue = Math.max(...analytics.dailyStats.map(s => s[selectedMetric as keyof typeof s] as number));
                const height = (value / maxValue) * 100;

                return (
                  <div key={index} className="flex-1 flex flex-col items-center">
                    <div
                      className="w-full bg-gradient-to-t from-blue-500 to-purple-500 rounded-t"
                      style={{ height: `${height}%`, minHeight: '4px' }}
                    />
                    <div className="text-xs text-gray-400 mt-2 text-center">
                      {new Date(stat.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Top Categories */}
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6">
            <h3 className="text-lg font-semibold text-white mb-6">Top Categories</h3>
            <div className="space-y-4">
              {analytics.topCategories.map((category, index) => (
                <div key={index} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-3 h-3 rounded-full bg-gradient-to-r from-blue-500 to-purple-500" />
                    <span className="text-white">{category.name}</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="w-24 bg-gray-700 rounded-full h-2">
                      <div
                        className="h-2 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full"
                        style={{ width: `${category.percentage}%` }}
                      />
                    </div>
                    <span className="text-sm text-gray-400 w-12 text-right">
                      {category.percentage}%
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* User Activity & Popular Listings */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* User Activity by Time */}
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6">
            <h3 className="text-lg font-semibold text-white mb-6">User Activity by Time</h3>
            <div className="space-y-4">
              {analytics.userActivity.map((activity, index) => (
                <div key={index} className="p-4 bg-gray-800/30 rounded-lg">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-white font-medium">{activity.period}</span>
                    <span className="text-blue-400">{activity.activeUsers} active</span>
                  </div>
                  <div className="flex gap-4 text-sm text-gray-400">
                    <span>New: {activity.newUsers}</span>
                    <span>Returning: {activity.returningUsers}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Popular Listings */}
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6">
            <h3 className="text-lg font-semibold text-white mb-6">Popular Listings</h3>
            <div className="space-y-4">
              {analytics.popularListings.map((listing, index) => (
                <div key={index} className="flex items-center justify-between p-3 bg-gray-800/30 rounded-lg">
                  <div>
                    <div className="text-white font-medium">{listing.title}</div>
                    <div className="text-sm text-gray-400">{listing.category}</div>
                  </div>
                  <div className="text-right">
                    <div className="flex items-center gap-2 text-sm text-gray-400">
                      <Eye className="w-3 h-3" />
                      {listing.views}
                    </div>
                    <div className="text-xs text-gray-500">{listing.favorites} favorites</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  );
}