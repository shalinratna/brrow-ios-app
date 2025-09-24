'use client';

import { useState, useEffect } from 'react';
import AdminLayout from '../../components/AdminLayout';

interface GarageSale {
  id: string;
  title: string;
  description: string;
  location: string;
  date: string;
  status: 'PENDING' | 'ACTIVE' | 'CANCELLED';
  host?: {
    id: string;
    email: string;
    firstName?: string;
    lastName?: string;
  };
  itemCount: number;
  createdAt: string;
}

export default function GarageSalesPage() {
  const [garageSales, setGarageSales] = useState<GarageSale[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedSales, setSelectedSales] = useState<string[]>([]);

  const fetchGarageSales = async () => {
    setLoading(true);
    setError(null);
    try {
      const adminToken = localStorage.getItem('adminToken');
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/garage-sales`, {
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
      if (data.garageSales) {
        setGarageSales(data.garageSales);
      } else {
        setGarageSales([]);
      }

    } catch (error) {
      console.error('Error fetching garage sales:', error);
      setError('Failed to connect to backend server');

      // Demo data fallback
      setGarageSales([
        {
          id: '1',
          title: 'Spring Cleaning Sale',
          description: 'Clothes, books, and household items',
          location: 'San Francisco, CA',
          date: '2024-03-15',
          status: 'ACTIVE',
          host: {
            id: 'user1',
            email: 'sarah@example.com',
            firstName: 'Sarah',
            lastName: 'Johnson'
          },
          itemCount: 25,
          createdAt: new Date().toISOString()
        },
        {
          id: '2',
          title: 'Moving Sale - Everything Must Go!',
          description: 'Furniture, electronics, kitchen appliances',
          location: 'Oakland, CA',
          date: '2024-03-20',
          status: 'PENDING',
          host: {
            id: 'user2',
            email: 'mike@example.com',
            firstName: 'Mike',
            lastName: 'Chen'
          },
          itemCount: 42,
          createdAt: new Date().toISOString()
        }
      ]);
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

  const handleSingleAction = async (action: 'approve' | 'cancel' | 'delete', saleId: string) => {
    const confirmAction = confirm(`Are you sure you want to ${action} this garage sale?`);
    if (!confirmAction) return;

    try {
      const adminToken = localStorage.getItem('adminToken');

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

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ACTIVE': return 'bg-green-100 text-green-800';
      case 'PENDING': return 'bg-yellow-100 text-yellow-800';
      case 'CANCELLED': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-3xl font-bold">Garage Sales Management</h1>
          <div className="text-sm text-gray-500">
            Total: {garageSales.length} garage sales
          </div>
        </div>

        {/* Search and Filter Controls */}
        <div className="bg-white p-6 rounded-lg shadow">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Search
              </label>
              <input
                type="text"
                placeholder="Search by title, location, or host email..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Status Filter
              </label>
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">All Statuses</option>
                <option value="ACTIVE">Active</option>
                <option value="PENDING">Pending</option>
                <option value="CANCELLED">Cancelled</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Bulk Actions
              </label>
              <div className="flex space-x-2">
                <button
                  onClick={() => handleBulkAction('approve')}
                  disabled={selectedSales.length === 0}
                  className="px-3 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed text-sm"
                >
                  Approve ({selectedSales.length})
                </button>
                <button
                  onClick={() => handleBulkAction('cancel')}
                  disabled={selectedSales.length === 0}
                  className="px-3 py-2 bg-yellow-600 text-white rounded-md hover:bg-yellow-700 disabled:opacity-50 disabled:cursor-not-allowed text-sm"
                >
                  Cancel ({selectedSales.length})
                </button>
                <button
                  onClick={() => handleBulkAction('delete')}
                  disabled={selectedSales.length === 0}
                  className="px-3 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed text-sm"
                >
                  Delete ({selectedSales.length})
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Error Display */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-md p-4">
            <p className="text-red-700">{error}</p>
          </div>
        )}

        {/* Loading State */}
        {loading ? (
          <div className="bg-white rounded-lg shadow p-8">
            <div className="flex items-center justify-center">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              <span className="ml-2">Loading garage sales...</span>
            </div>
          </div>
        ) : (
          /* Garage Sales Table */
          <div className="bg-white shadow rounded-lg overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    <input
                      type="checkbox"
                      checked={selectedSales.length === filteredSales.length && filteredSales.length > 0}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedSales(filteredSales.map(sale => sale.id));
                        } else {
                          setSelectedSales([]);
                        }
                      }}
                      className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    />
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Garage Sale
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Host
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Location
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Date
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Items
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredSales.map((sale) => (
                  <tr key={sale.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <input
                        type="checkbox"
                        checked={selectedSales.includes(sale.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedSales([...selectedSales, sale.id]);
                          } else {
                            setSelectedSales(selectedSales.filter(id => id !== sale.id));
                          }
                        }}
                        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      />
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm font-medium text-gray-900">{sale.title}</div>
                        <div className="text-sm text-gray-500">{sale.description}</div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">
                        {sale.host?.firstName && sale.host?.lastName
                          ? `${sale.host.firstName} ${sale.host.lastName}`
                          : sale.host?.email || 'Unknown'}
                      </div>
                      <div className="text-sm text-gray-500">{sale.host?.email}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {sale.location}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {new Date(sale.date).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {sale.itemCount} items
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(sale.status)}`}>
                        {sale.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div className="flex space-x-2">
                        {sale.status === 'PENDING' && (
                          <button
                            onClick={() => handleSingleAction('approve', sale.id)}
                            className="text-green-600 hover:text-green-900"
                          >
                            Approve
                          </button>
                        )}
                        {sale.status === 'ACTIVE' && (
                          <button
                            onClick={() => handleSingleAction('cancel', sale.id)}
                            className="text-yellow-600 hover:text-yellow-900"
                          >
                            Cancel
                          </button>
                        )}
                        <button
                          onClick={() => handleSingleAction('delete', sale.id)}
                          className="text-red-600 hover:text-red-900"
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {filteredSales.length === 0 && !loading && (
              <div className="text-center py-8">
                <p className="text-gray-500">No garage sales found.</p>
              </div>
            )}
          </div>
        )}
      </div>
    </AdminLayout>
  );
}