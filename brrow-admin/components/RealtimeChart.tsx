'use client';

import { useEffect, useState } from 'react';
import { LineChart, Line, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { motion } from 'framer-motion';

export default function RealtimeChart() {
  const [data, setData] = useState<any[]>([]);
  const [chartType, setChartType] = useState<'users' | 'listings' | 'revenue'>('users');

  useEffect(() => {
    // Generate initial data
    const initialData = Array.from({ length: 24 }, (_, i) => ({
      time: `${i}:00`,
      users: Math.floor(Math.random() * 100) + 20,
      listings: Math.floor(Math.random() * 50) + 10,
      revenue: Math.random() * 1000 + 100
    }));
    setData(initialData);

    // Simulate real-time updates
    const interval = setInterval(() => {
      setData(prev => {
        const newData = [...prev.slice(1)];
        const lastHour = parseInt(prev[prev.length - 1].time.split(':')[0]);
        const newHour = (lastHour + 1) % 24;
        newData.push({
          time: `${newHour}:00`,
          users: Math.floor(Math.random() * 100) + 20,
          listings: Math.floor(Math.random() * 50) + 10,
          revenue: Math.random() * 1000 + 100
        });
        return newData;
      });
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  const chartConfigs = {
    users: { color: '#3b82f6', label: 'Active Users' },
    listings: { color: '#a855f7', label: 'New Listings' },
    revenue: { color: '#10b981', label: 'Revenue ($)' }
  };

  const config = chartConfigs[chartType];

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6"
    >
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-lg font-semibold text-white">Real-time Analytics</h2>
        <div className="flex gap-2">
          {Object.entries(chartConfigs).map(([key, value]) => (
            <button
              key={key}
              onClick={() => setChartType(key as typeof chartType)}
              className={`px-3 py-1 rounded-lg text-sm font-medium transition-all ${
                chartType === key
                  ? 'bg-gradient-to-r from-blue-500 to-purple-500 text-white'
                  : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
              }`}
            >
              {value.label}
            </button>
          ))}
        </div>
      </div>

      <ResponsiveContainer width="100%" height={300}>
        <AreaChart data={data}>
          <defs>
            <linearGradient id={`gradient-${chartType}`} x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor={config.color} stopOpacity={0.3}/>
              <stop offset="95%" stopColor={config.color} stopOpacity={0}/>
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
          <XAxis 
            dataKey="time" 
            stroke="#9ca3af"
            style={{ fontSize: 12 }}
          />
          <YAxis 
            stroke="#9ca3af"
            style={{ fontSize: 12 }}
          />
          <Tooltip 
            contentStyle={{ 
              backgroundColor: '#1f2937',
              border: '1px solid #374151',
              borderRadius: '8px'
            }}
            labelStyle={{ color: '#9ca3af' }}
          />
          <Area
            type="monotone"
            dataKey={chartType}
            stroke={config.color}
            strokeWidth={2}
            fill={`url(#gradient-${chartType})`}
          />
        </AreaChart>
      </ResponsiveContainer>
    </motion.div>
  );
}