'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  Car,
  Search,
  Edit,
  Trash2,
  Eye,
  Calendar,
  MapPin,
  Users,
  DollarSign
} from 'lucide-react';

interface GarageSale {
  id: string;
  title: string;
  description?: string;
  location: string;
  startDate: string;
  endDate: string;
  status: string;
  totalItems?: number;
  estimatedValue?: number;
  host?: {
    id: string;
    email: string;
    firstName?: string;
    lastName?: string;
  };
  attendees?: number;
  createdAt: string;
}

export default function GarageSalesManagement() {
  const [garageSales, setGarageSales] = useState<GarageSale[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedSales, setSelectedSales] = useState<string[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [error, setError] = useState<string | null>(null);

  const fetchGarageSales = async () => {
    setLoading(true);
    setError(null);

    try {
      const adminToken = localStorage.getItem('adminToken');
      if (!adminToken) {
        setError('No admin token found. Please log in again.');
        setLoading(false);
        return;
      }

      // Try to fetch real garage sales from backend
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/garage-sales`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        console.log('Garage Sales API Response:', data);

        if (data.success && data.data) {
          setGarageSales(data.data);
          console.log(`Loaded ${data.data.length} real garage sales from database`);
        } else {
          setError('No garage sales data available');
        }
      } else {
        if (response.status === 404) {
          setError('Garage sales feature not yet implemented in backend');
        } else if (response.status === 401) {
          setError('Authentication failed. Please log in again.');
        } else {
          setError(`API error: ${response.status}`);
        }
      }

    } catch (error) {
      console.error('Error fetching garage sales:', error);
      setError('Failed to connect to backend server');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchGarageSales();
  }, []);

  const handleBulkAction = async (action: 'approve' | 'cancel' | 'delete') => {
    if (selectedSales.length === 0) return;

    const confirmAction = confirm(`Are you sure you want to ${action} ${selectedSales.length} garage sales?`);
    if (!confirmAction) return;

    try {
      const adminToken = localStorage.getItem('adminToken');

      for (const saleId of selectedSales) {
        const endpoint = action === 'delete'
          ? `/api/admin/garage-sales/${saleId}`
          : `/api/admin/garage-sales/${saleId}`;

        const method = action === 'delete' ? 'DELETE' : 'PATCH';
        const body = action !== 'delete' ? {
          status: action === 'approve' ? 'ACTIVE' : 'CANCELLED'
        } : undefined;

        await fetch(`${process.env.NEXT_PUBLIC_API_URL}${endpoint}`, {
          method,
          headers: {
            'Authorization': `Bearer ${adminToken}`,
            'Content-Type': 'application/json'
          },
          body: body ? JSON.stringify(body) : undefined
        });
      }

      setSelectedSales([]);
      fetchGarageSales();
    } catch (error) {
      console.error(`Error performing ${action}:`, error);
    }
  };

  const filteredSales = garageSales.filter(sale => {
    const matchesSearch = sale.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         sale.location.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         sale.host?.email.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = statusFilter === 'all' || sale.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950 p-6">
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="flex items-center gap-3">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
            <span className="text-gray-400">Loading garage sales from database...</span>
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
              onClick={fetchGarageSales}
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
              Garage Sales Management
            </h1>
            <p className="text-gray-400 mt-2">
              Manage all garage sale events • {garageSales.length} total events from database
            </p>
          </div>
          <button
            onClick={fetchGarageSales}
            className="px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white hover:bg-gray-700 flex items-center gap-2"
          >
            <Eye className="w-4 h-4" />
            Refresh
          </button>
        </div>

        {/* Empty State */}
        <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl overflow-hidden">
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <Car className="w-16 h-16 text-gray-600 mx-auto mb-4" />
              <div className="text-gray-400 text-lg mb-2">No garage sales found</div>
              <div className="text-gray-500 text-sm">
                {garageSales.length === 0 ? 'No garage sales in database yet' : 'Try adjusting your search'}
              </div>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mt-6">
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Total Events</p>
                <p className="text-2xl font-bold text-white">{garageSales.length}</p>
              </div>
              <Car className="w-8 h-8 text-blue-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Active Events</p>
                <p className="text-2xl font-bold text-white">
                  {garageSales.filter(sale => sale.status === 'ACTIVE').length}
                </p>
              </div>
              <Calendar className="w-8 h-8 text-green-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Total Attendees</p>
                <p className="text-2xl font-bold text-white">
                  {garageSales.reduce((sum, sale) => sum + (sale.attendees || 0), 0)}
                </p>
              </div>
              <Users className="w-8 h-8 text-purple-400" />
            </div>
          </div>
          <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-400">Total Value</p>
                <p className="text-2xl font-bold text-white">
                  ${garageSales.reduce((sum, sale) => sum + (sale.estimatedValue || 0), 0).toLocaleString()}
                </p>
              </div>
              <DollarSign className="w-8 h-8 text-yellow-400" />
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  );
}