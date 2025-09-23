'use client';

import { useState, useEffect } from 'react';
import { 
  Activity, 
  Users, 
  Package, 
  DollarSign, 
  TrendingUp,
  AlertCircle,
  Server,
  Cpu,
  HardDrive,
  Wifi
} from 'lucide-react';
import { motion } from 'framer-motion';
import RealtimeChart from '@/components/RealtimeChart';
import ServerHealth from '@/components/ServerHealth';
import QuickActions from '@/components/QuickActions';
import RecentActivity from '@/components/RecentActivity';

export default function Dashboard() {
  const [currentTime, setCurrentTime] = useState('');
  const [serverHealth, setServerHealth] = useState({ status: 'healthy', issues: [] as string[] });
  const [todayStats, setTodayStats] = useState({
    activeUsers: 0,
    newListings: 0,
    transactions: 0,
    revenue: 0,
    serverLoad: 0,
    responseTime: 0
  });

  const fetchStats = async () => {
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/stats`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        setTodayStats({
          activeUsers: data.users?.active || 0,
          newListings: data.listings?.today || 0,
          transactions: data.transactions?.total || 0,
          revenue: data.transactions?.revenue || 0,
          serverLoad: Math.random() * 100, // Server load simulation
          responseTime: Math.random() * 200 + 50 // Response time simulation
        });
      } else {
        console.error('Failed to fetch stats:', response.status);
      }
    } catch (error) {
      console.error('Error fetching stats:', error);
    }
  };

  // Update current time on client side only
  useEffect(() => {
    const updateTime = () => {
      setCurrentTime(new Date().toLocaleString());
    };

    updateTime(); // Initial time
    const timeInterval = setInterval(updateTime, 1000); // Update every second

    return () => clearInterval(timeInterval);
  }, []);

  useEffect(() => {
    fetchStats();

    // Refresh stats every 30 seconds
    const interval = setInterval(() => {
      fetchStats();
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950">
      {/* Header */}
      <header className="border-b border-gray-800 bg-gray-900/50 backdrop-blur-xl">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
                Shaiitech Founder Panel
              </h1>
              <p className="text-sm text-gray-400 mt-1">
                Real-time analytics and control center
              </p>
            </div>
            <div className="flex items-center gap-4">
              <span className="text-sm text-gray-400">
                {currentTime}
              </span>
              <div className="flex items-center gap-2">
                <div className={`w-2 h-2 rounded-full ${serverHealth.status === 'healthy' ? 'bg-green-500' : 'bg-red-500'} animate-pulse`} />
                <span className="text-sm text-gray-300">System {serverHealth.status}</span>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Server Issues Alert (Priority) */}
      {serverHealth.issues.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mx-6 mt-6 p-4 bg-red-900/20 border border-red-800 rounded-lg"
        >
          <div className="flex items-center gap-3">
            <AlertCircle className="w-5 h-5 text-red-400" />
            <div>
              <h3 className="font-semibold text-red-400">Server Issues Detected</h3>
              <p className="text-sm text-gray-300 mt-1">
                {serverHealth.issues.join(', ')}
              </p>
            </div>
          </div>
        </motion.div>
      )}

      {/* Main Grid */}
      <div className="p-6 grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Today's Metrics */}
        <div className="lg:col-span-3 space-y-6">
          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <StatCard
              title="Active Users"
              value={todayStats.activeUsers}
              icon={Users}
              trend="+12%"
              color="blue"
            />
            <StatCard
              title="New Listings"
              value={todayStats.newListings}
              icon={Package}
              trend="+8%"
              color="purple"
            />
            <StatCard
              title="Transactions"
              value={todayStats.transactions}
              icon={Activity}
              trend="+23%"
              color="green"
            />
            <StatCard
              title="Revenue"
              value={`$${todayStats.revenue.toFixed(2)}`}
              icon={DollarSign}
              trend="+15%"
              color="yellow"
            />
          </div>

          {/* Real-time Chart */}
          <RealtimeChart />

          {/* Recent Activity */}
          <RecentActivity />
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Server Health */}
          <ServerHealth />

          {/* Quick Actions */}
          <QuickActions />
        </div>
      </div>
    </div>
  );
}

interface StatCardProps {
  title: string;
  value: string | number;
  icon: React.ElementType;
  trend: string;
  color: 'blue' | 'purple' | 'green' | 'yellow';
}

function StatCard({ title, value, icon: Icon, trend, color }: StatCardProps) {
  const colorClasses = {
    blue: 'from-blue-500 to-blue-600',
    purple: 'from-purple-500 to-purple-600',
    green: 'from-green-500 to-green-600',
    yellow: 'from-yellow-500 to-yellow-600'
  };

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-4"
    >
      <div className="flex items-center justify-between mb-3">
        <div className={`p-2 bg-gradient-to-br ${colorClasses[color]} rounded-lg`}>
          <Icon className="w-5 h-5 text-white" />
        </div>
        <span className="text-xs text-green-400 font-medium">{trend}</span>
      </div>
      <div>
        <p className="text-2xl font-bold text-white">{value}</p>
        <p className="text-sm text-gray-400 mt-1">{title}</p>
      </div>
    </motion.div>
  );
}
