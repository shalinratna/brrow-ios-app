'use client';

import { useEffect, useState } from 'react';
import { Server, Cpu, HardDrive, Wifi, AlertTriangle, CheckCircle } from 'lucide-react';
import { motion } from 'framer-motion';

export default function ServerHealth() {
  const [metrics, setMetrics] = useState({
    cpu: 0,
    memory: 0,
    disk: 0,
    network: 0,
    uptime: '0h'
  });

  useEffect(() => {
    const interval = setInterval(() => {
      setMetrics({
        cpu: Math.random() * 100,
        memory: Math.random() * 100,
        disk: 30 + Math.random() * 40,
        network: Math.random() * 1000,
        uptime: `${Math.floor(Math.random() * 24)}h ${Math.floor(Math.random() * 60)}m`
      });
    }, 3000);

    return () => clearInterval(interval);
  }, []);

  const getStatusColor = (value: number) => {
    if (value < 50) return 'text-green-400';
    if (value < 80) return 'text-yellow-400';
    return 'text-red-400';
  };

  const getBarColor = (value: number) => {
    if (value < 50) return 'bg-green-500';
    if (value < 80) return 'bg-yellow-500';
    return 'bg-red-500';
  };

  return (
    <motion.div
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl p-6"
    >
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-white flex items-center gap-2">
          <Server className="w-5 h-5" />
          Server Health
        </h3>
        {metrics.cpu < 80 && metrics.memory < 80 ? (
          <CheckCircle className="w-5 h-5 text-green-400" />
        ) : (
          <AlertTriangle className="w-5 h-5 text-yellow-400" />
        )}
      </div>

      <div className="space-y-4">
        <MetricRow
          icon={Cpu}
          label="CPU Usage"
          value={metrics.cpu}
          unit="%"
        />
        <MetricRow
          icon={HardDrive}
          label="Memory"
          value={metrics.memory}
          unit="%"
        />
        <MetricRow
          icon={HardDrive}
          label="Disk Usage"
          value={metrics.disk}
          unit="%"
        />
        <MetricRow
          icon={Wifi}
          label="Network"
          value={metrics.network}
          unit=" Mbps"
        />
      </div>

      <div className="mt-4 pt-4 border-t border-gray-800">
        <div className="flex items-center justify-between">
          <span className="text-sm text-gray-400">Uptime</span>
          <span className="text-sm font-medium text-white">{metrics.uptime}</span>
        </div>
      </div>
    </motion.div>
  );
}

interface MetricRowProps {
  icon: React.ElementType;
  label: string;
  value: number;
  unit: string;
}

function MetricRow({ icon: Icon, label, value, unit }: MetricRowProps) {
  const getBarColor = (value: number) => {
    if (value < 50) return 'bg-green-500';
    if (value < 80) return 'bg-yellow-500';
    return 'bg-red-500';
  };

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Icon className="w-4 h-4 text-gray-400" />
          <span className="text-sm text-gray-300">{label}</span>
        </div>
        <span className={`text-sm font-medium ${value < 50 ? 'text-green-400' : value < 80 ? 'text-yellow-400' : 'text-red-400'}`}>
          {value.toFixed(1)}{unit}
        </span>
      </div>
      <div className="w-full bg-gray-800 rounded-full h-2 overflow-hidden">
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: `${value}%` }}
          transition={{ duration: 0.5 }}
          className={`h-full ${getBarColor(value)}`}
        />
      </div>
    </div>
  );
}