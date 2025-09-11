'use client';

import { 
  RefreshCw, 
  Trash2, 
  Database, 
  Shield, 
  Download,
  Upload,
  AlertTriangle,
  Power
} from 'lucide-react';
import { motion } from 'framer-motion';
import { toast } from 'sonner';

export default function QuickActions() {
  const actions = [
    {
      icon: RefreshCw,
      label: 'Restart Server',
      color: 'blue',
      action: () => {
        toast.loading('Restarting server...');
        setTimeout(() => {
          toast.success('Server restarted successfully');
        }, 2000);
      }
    },
    {
      icon: Database,
      label: 'Backup Database',
      color: 'green',
      action: () => {
        toast.loading('Creating backup...');
        setTimeout(() => {
          toast.success('Database backup completed');
        }, 3000);
      }
    },
    {
      icon: Trash2,
      label: 'Clear Cache',
      color: 'yellow',
      action: () => {
        toast.loading('Clearing cache...');
        setTimeout(() => {
          toast.success('Cache cleared successfully');
        }, 1500);
      }
    },
    {
      icon: Shield,
      label: 'Security Scan',
      color: 'purple',
      action: () => {
        toast.loading('Running security scan...');
        setTimeout(() => {
          toast.success('No vulnerabilities detected');
        }, 4000);
      }
    }
  ];

  const colorClasses = {
    blue: 'hover:bg-blue-900/20 hover:border-blue-700',
    green: 'hover:bg-green-900/20 hover:border-green-700',
    yellow: 'hover:bg-yellow-900/20 hover:border-yellow-700',
    purple: 'hover:bg-purple-900/20 hover:border-purple-700'
  };

  return (
    <motion.div
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ delay: 0.1 }}
      className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6"
    >
      <h3 className="text-lg font-semibold text-white mb-4">Quick Actions</h3>

      <div className="grid grid-cols-2 gap-3">
        {actions.map((action, index) => (
          <motion.button
            key={index}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={action.action}
            className={`p-3 bg-gray-800/50 border border-gray-700 rounded-lg transition-all ${
              colorClasses[action.color as keyof typeof colorClasses]
            }`}
          >
            <action.icon className="w-5 h-5 text-gray-300 mx-auto mb-2" />
            <span className="text-xs text-gray-400 block">{action.label}</span>
          </motion.button>
        ))}
      </div>

      <div className="mt-4 pt-4 border-t border-gray-800">
        <button
          onClick={() => {
            toast.error('Emergency shutdown initiated');
          }}
          className="w-full p-3 bg-red-900/20 border border-red-800 rounded-lg hover:bg-red-900/30 transition-all flex items-center justify-center gap-2"
        >
          <Power className="w-4 h-4 text-red-400" />
          <span className="text-sm text-red-400 font-medium">Emergency Shutdown</span>
        </button>
      </div>
    </motion.div>
  );
}