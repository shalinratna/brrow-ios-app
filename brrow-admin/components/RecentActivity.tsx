'use client';

import { useEffect, useState } from 'react';
import { 
  User, 
  Package, 
  MessageSquare, 
  CreditCard,
  AlertCircle,
  CheckCircle,
  XCircle
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface Activity {
  id: string;
  type: 'user' | 'listing' | 'message' | 'transaction' | 'error' | 'success';
  message: string;
  timestamp: Date;
  user?: string;
}

export default function RecentActivity() {
  const [activities, setActivities] = useState<Activity[]>([]);

  useEffect(() => {
    // Generate initial activities
    const initialActivities: Activity[] = [
      {
        id: '1',
        type: 'user',
        message: 'New user registered',
        user: 'john.doe@example.com',
        timestamp: new Date()
      },
      {
        id: '2',
        type: 'listing',
        message: 'New listing created: MacBook Pro 16"',
        user: 'seller123',
        timestamp: new Date(Date.now() - 1000 * 60 * 5)
      },
      {
        id: '3',
        type: 'transaction',
        message: 'Payment processed: $299.00',
        user: 'buyer456',
        timestamp: new Date(Date.now() - 1000 * 60 * 10)
      }
    ];
    setActivities(initialActivities);

    // Simulate real-time activity
    const interval = setInterval(() => {
      const types: Activity['type'][] = ['user', 'listing', 'message', 'transaction', 'error', 'success'];
      const messages = {
        user: ['New user registered', 'User logged in', 'Profile updated'],
        listing: ['New listing created', 'Listing updated', 'Listing deleted'],
        message: ['New message received', 'Support ticket opened'],
        transaction: ['Payment processed', 'Refund issued'],
        error: ['Failed login attempt', 'API rate limit exceeded'],
        success: ['Backup completed', 'Cache cleared']
      };

      const type = types[Math.floor(Math.random() * types.length)];
      const messageList = messages[type];
      const message = messageList[Math.floor(Math.random() * messageList.length)];

      const newActivity: Activity = {
        id: Date.now().toString(),
        type,
        message,
        user: `user${Math.floor(Math.random() * 1000)}`,
        timestamp: new Date()
      };

      setActivities(prev => [newActivity, ...prev.slice(0, 9)]);
    }, 8000);

    return () => clearInterval(interval);
  }, []);

  const getIcon = (type: Activity['type']) => {
    const icons = {
      user: User,
      listing: Package,
      message: MessageSquare,
      transaction: CreditCard,
      error: XCircle,
      success: CheckCircle
    };
    return icons[type];
  };

  const getColor = (type: Activity['type']) => {
    const colors = {
      user: 'text-blue-400',
      listing: 'text-purple-400',
      message: 'text-green-400',
      transaction: 'text-yellow-400',
      error: 'text-red-400',
      success: 'text-green-400'
    };
    return colors[type];
  };

  const formatTime = (date: Date) => {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    return `${Math.floor(hours / 24)}d ago`;
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 0.2 }}
      className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6"
    >
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-lg font-semibold text-white">Recent Activity</h2>
        <button className="text-sm text-blue-400 hover:text-blue-300 transition-colors">
          View All →
        </button>
      </div>

      <div className="space-y-3 max-h-[400px] overflow-y-auto">
        <AnimatePresence mode="popLayout">
          {activities.map((activity) => {
            const Icon = getIcon(activity.type);
            return (
              <motion.div
                key={activity.id}
                layout
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                className="flex items-start gap-3 p-3 bg-gray-800/30 rounded-lg hover:bg-gray-800/50 transition-all"
              >
                <div className={`p-2 bg-gray-800 rounded-lg ${getColor(activity.type)}`}>
                  <Icon className="w-4 h-4" />
                </div>
                <div className="flex-1">
                  <p className="text-sm text-gray-200">{activity.message}</p>
                  {activity.user && (
                    <p className="text-xs text-gray-500 mt-1">by {activity.user}</p>
                  )}
                </div>
                <span className="text-xs text-gray-500">
                  {formatTime(activity.timestamp)}
                </span>
              </motion.div>
            );
          })}
        </AnimatePresence>
      </div>
    </motion.div>
  );
}