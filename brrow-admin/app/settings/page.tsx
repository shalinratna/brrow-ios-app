'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  Settings,
  Save,
  RefreshCw,
  Bell,
  Shield,
  DollarSign,
  Mail,
  Globe,
  Database,
  Zap,
  Eye,
  EyeOff,
  CheckCircle,
  AlertTriangle,
  Info,
  LogOut
} from 'lucide-react';

interface PlatformSettings {
  general: {
    platformName: string;
    platformDescription: string;
    maintenanceMode: boolean;
    registrationEnabled: boolean;
    maxListingsPerUser: number;
    defaultLanguage: string;
    timezone: string;
  };

  fees: {
    platformFeePercentage: number;
    minimumFee: number;
    maximumFee: number;
    protectionFeePercentage: number;
    protectionCoverage: number;
  };

  security: {
    requireEmailVerification: boolean;
    requirePhoneVerification: boolean;
    enableTwoFactorAuth: boolean;
    sessionTimeoutMinutes: number;
    maxLoginAttempts: number;
    passwordMinLength: number;
  };

  notifications: {
    emailNotifications: boolean;
    pushNotifications: boolean;
    smsNotifications: boolean;
    marketingEmails: boolean;
    systemAlerts: boolean;
  };

  integrations: {
    stripeEnabled: boolean;
    stripePublishableKey: string;
    stripeSecretKey: string;
    twilioEnabled: boolean;
    twilioAccountSid: string;
    twilioAuthToken: string;
    emailProvider: 'sendgrid' | 'mailgun' | 'ses';
    emailApiKey: string;
  };

  features: {
    enableGarageSales: boolean;
    enableBubbles: boolean;
    enableMessaging: boolean;
    enableReviews: boolean;
    enableFavorites: boolean;
    enableAnalytics: boolean;
  };
}

export default function SettingsManagement() {
  const [settings, setSettings] = useState<PlatformSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [activeTab, setActiveTab] = useState('general');
  const [showSecrets, setShowSecrets] = useState<{[key: string]: boolean}>({});
  const [unsavedChanges, setUnsavedChanges] = useState(false);

  const fetchSettings = async () => {
    setLoading(true);
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/settings`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        setSettings(data.data || data);
      } else {
        // Demo settings data
        setSettings({
          general: {
            platformName: 'Brrow',
            platformDescription: 'Peer-to-peer rental and selling marketplace',
            maintenanceMode: false,
            registrationEnabled: true,
            maxListingsPerUser: 50,
            defaultLanguage: 'en',
            timezone: 'America/New_York'
          },
          fees: {
            platformFeePercentage: 10,
            minimumFee: 1,
            maximumFee: 100,
            protectionFeePercentage: 10,
            protectionCoverage: 120
          },
          security: {
            requireEmailVerification: true,
            requirePhoneVerification: false,
            enableTwoFactorAuth: false,
            sessionTimeoutMinutes: 120,
            maxLoginAttempts: 5,
            passwordMinLength: 8
          },
          notifications: {
            emailNotifications: true,
            pushNotifications: true,
            smsNotifications: false,
            marketingEmails: true,
            systemAlerts: true
          },
          integrations: {
            stripeEnabled: true,
            stripePublishableKey: 'pk_test_...',
            stripeSecretKey: 'sk_test_...',
            twilioEnabled: false,
            twilioAccountSid: '',
            twilioAuthToken: '',
            emailProvider: 'sendgrid',
            emailApiKey: 'SG...'
          },
          features: {
            enableGarageSales: true,
            enableBubbles: true,
            enableMessaging: true,
            enableReviews: true,
            enableFavorites: true,
            enableAnalytics: true
          }
        });
      }
    } catch (error) {
      console.error('Error fetching settings:', error);
      // Set default settings on error
      setSettings({
        general: {
          platformName: 'Brrow',
          platformDescription: 'Peer-to-peer rental marketplace',
          maintenanceMode: false,
          registrationEnabled: true,
          maxListingsPerUser: 50,
          defaultLanguage: 'en',
          timezone: 'UTC'
        },
        fees: { platformFeePercentage: 10, minimumFee: 1, maximumFee: 100, protectionFeePercentage: 10, protectionCoverage: 120 },
        security: { requireEmailVerification: true, requirePhoneVerification: false, enableTwoFactorAuth: false, sessionTimeoutMinutes: 120, maxLoginAttempts: 5, passwordMinLength: 8 },
        notifications: { emailNotifications: true, pushNotifications: true, smsNotifications: false, marketingEmails: true, systemAlerts: true },
        integrations: { stripeEnabled: false, stripePublishableKey: '', stripeSecretKey: '', twilioEnabled: false, twilioAccountSid: '', twilioAuthToken: '', emailProvider: 'sendgrid', emailApiKey: '' },
        features: { enableGarageSales: true, enableBubbles: true, enableMessaging: true, enableReviews: true, enableFavorites: true, enableAnalytics: true }
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSettings();
  }, []);

  const handleSaveSettings = async () => {
    if (!settings) return;

    setSaving(true);
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/settings`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(settings)
      });

      if (response.ok) {
        setUnsavedChanges(false);
        // Show success message
      }
    } catch (error) {
      console.error('Error saving settings:', error);
    } finally {
      setSaving(false);
    }
  };

  const updateSetting = (section: keyof PlatformSettings, key: string, value: any) => {
    if (!settings) return;

    setSettings({
      ...settings,
      [section]: {
        ...settings[section],
        [key]: value
      }
    });
    setUnsavedChanges(true);
  };

  const toggleSecret = (key: string) => {
    setShowSecrets(prev => ({ ...prev, [key]: !prev[key] }));
  };

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    window.location.href = '/login';
  };

  const tabs = [
    { id: 'general', name: 'General', icon: Globe },
    { id: 'fees', name: 'Fees & Pricing', icon: DollarSign },
    { id: 'security', name: 'Security', icon: Shield },
    { id: 'notifications', name: 'Notifications', icon: Bell },
    { id: 'integrations', name: 'Integrations', icon: Zap },
    { id: 'features', name: 'Features', icon: Settings }
  ];

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950 flex items-center justify-center">
        <div className="flex items-center gap-3">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
          <span className="text-gray-400">Loading settings...</span>
        </div>
      </div>
    );
  }

  if (!settings) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-xl text-white mb-2">No Settings Data</h2>
          <p className="text-gray-400">Unable to load platform settings</p>
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
              Platform Settings
            </h1>
            <p className="text-gray-400 mt-2">Configure platform settings and integrations</p>
          </div>

          <div className="flex gap-3">
            <button
              onClick={fetchSettings}
              className="px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white hover:bg-gray-700 flex items-center gap-2"
            >
              <RefreshCw className="w-4 h-4" />
              Refresh
            </button>

            <button
              onClick={handleSaveSettings}
              disabled={!unsavedChanges || saving}
              className={`px-4 py-2 rounded-lg flex items-center gap-2 ${
                unsavedChanges && !saving
                  ? 'bg-gradient-to-r from-blue-500 to-purple-600 text-white hover:from-blue-600 hover:to-purple-700'
                  : 'bg-gray-600 text-gray-300 cursor-not-allowed'
              }`}
            >
              {saving ? (
                <RefreshCw className="w-4 h-4 animate-spin" />
              ) : (
                <Save className="w-4 h-4" />
              )}
              {saving ? 'Saving...' : 'Save Changes'}
            </button>

            <button
              onClick={handleLogout}
              className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg flex items-center gap-2"
            >
              <LogOut className="w-4 h-4" />
              Logout
            </button>
          </div>
        </div>

        {/* Unsaved Changes Warning */}
        {unsavedChanges && (
          <div className="bg-yellow-900/20 border border-yellow-500/30 rounded-xl p-4 mb-6">
            <div className="flex items-center gap-2 text-yellow-400">
              <AlertTriangle className="w-5 h-5" />
              <span className="font-medium">You have unsaved changes</span>
            </div>
            <p className="text-yellow-400/80 text-sm mt-1">
              Don't forget to save your changes before leaving this page.
            </p>
          </div>
        )}

        {/* Settings Tabs */}
        <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-xl overflow-hidden">
          {/* Tab Navigation */}
          <div className="border-b border-gray-800">
            <nav className="flex overflow-x-auto">
              {tabs.map((tab) => {
                const TabIcon = tab.icon;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`flex items-center gap-2 px-6 py-4 text-sm font-medium whitespace-nowrap transition-colors ${
                      activeTab === tab.id
                        ? 'text-blue-400 border-b-2 border-blue-400 bg-gray-800/50'
                        : 'text-gray-400 hover:text-gray-300'
                    }`}
                  >
                    <TabIcon className="w-4 h-4" />
                    {tab.name}
                  </button>
                );
              })}
            </nav>
          </div>

          {/* Tab Content */}
          <div className="p-6">
            {activeTab === 'general' && (
              <div className="space-y-6">
                <h3 className="text-lg font-semibold text-white">General Settings</h3>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Platform Name
                    </label>
                    <input
                      type="text"
                      value={settings.general.platformName}
                      onChange={(e) => updateSetting('general', 'platformName', e.target.value)}
                      className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Default Language
                    </label>
                    <select
                      value={settings.general.defaultLanguage}
                      onChange={(e) => updateSetting('general', 'defaultLanguage', e.target.value)}
                      className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="en">English</option>
                      <option value="es">Spanish</option>
                      <option value="fr">French</option>
                      <option value="de">German</option>
                    </select>
                  </div>

                  <div className="md:col-span-2">
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Platform Description
                    </label>
                    <textarea
                      value={settings.general.platformDescription}
                      onChange={(e) => updateSetting('general', 'platformDescription', e.target.value)}
                      rows={3}
                      className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Max Listings Per User
                    </label>
                    <input
                      type="number"
                      value={settings.general.maxListingsPerUser}
                      onChange={(e) => updateSetting('general', 'maxListingsPerUser', parseInt(e.target.value))}
                      className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Timezone
                    </label>
                    <select
                      value={settings.general.timezone}
                      onChange={(e) => updateSetting('general', 'timezone', e.target.value)}
                      className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="America/New_York">Eastern Time</option>
                      <option value="America/Chicago">Central Time</option>
                      <option value="America/Denver">Mountain Time</option>
                      <option value="America/Los_Angeles">Pacific Time</option>
                      <option value="UTC">UTC</option>
                    </select>
                  </div>
                </div>

                <div className="space-y-4">
                  <div className="flex items-center justify-between p-4 bg-gray-800/30 rounded-lg">
                    <div>
                      <div className="text-white font-medium">Maintenance Mode</div>
                      <div className="text-sm text-gray-400">Temporarily disable the platform for maintenance</div>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.general.maintenanceMode}
                        onChange={(e) => updateSetting('general', 'maintenanceMode', e.target.checked)}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                  </div>

                  <div className="flex items-center justify-between p-4 bg-gray-800/30 rounded-lg">
                    <div>
                      <div className="text-white font-medium">User Registration</div>
                      <div className="text-sm text-gray-400">Allow new users to register</div>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.general.registrationEnabled}
                        onChange={(e) => updateSetting('general', 'registrationEnabled', e.target.checked)}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'fees' && (
              <div className="space-y-6">
                <h3 className="text-lg font-semibold text-white">Fees & Pricing</h3>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Platform Fee Percentage
                    </label>
                    <div className="relative">
                      <input
                        type="number"
                        step="0.1"
                        value={settings.fees.platformFeePercentage}
                        onChange={(e) => updateSetting('fees', 'platformFeePercentage', parseFloat(e.target.value))}
                        className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                      <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400">%</span>
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Protection Fee Percentage
                    </label>
                    <div className="relative">
                      <input
                        type="number"
                        step="0.1"
                        value={settings.fees.protectionFeePercentage}
                        onChange={(e) => updateSetting('fees', 'protectionFeePercentage', parseFloat(e.target.value))}
                        className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                      <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400">%</span>
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Minimum Fee
                    </label>
                    <div className="relative">
                      <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400">$</span>
                      <input
                        type="number"
                        step="0.01"
                        value={settings.fees.minimumFee}
                        onChange={(e) => updateSetting('fees', 'minimumFee', parseFloat(e.target.value))}
                        className="w-full pl-8 pr-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Maximum Fee
                    </label>
                    <div className="relative">
                      <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400">$</span>
                      <input
                        type="number"
                        step="0.01"
                        value={settings.fees.maximumFee}
                        onChange={(e) => updateSetting('fees', 'maximumFee', parseFloat(e.target.value))}
                        className="w-full pl-8 pr-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Protection Coverage
                    </label>
                    <div className="relative">
                      <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400">$</span>
                      <input
                        type="number"
                        value={settings.fees.protectionCoverage}
                        onChange={(e) => updateSetting('fees', 'protectionCoverage', parseInt(e.target.value))}
                        className="w-full pl-8 pr-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>
                </div>

                <div className="bg-blue-900/20 border border-blue-500/30 rounded-lg p-4">
                  <div className="flex items-start gap-2">
                    <Info className="w-5 h-5 text-blue-400 mt-0.5 flex-shrink-0" />
                    <div>
                      <div className="text-blue-400 font-medium">Fee Calculation</div>
                      <div className="text-blue-300/80 text-sm mt-1">
                        Total fees = Platform fee ({settings.fees.platformFeePercentage}%) + Protection fee ({settings.fees.protectionFeePercentage}%)
                        <br />
                        Example: $100 rental = ${((settings.fees.platformFeePercentage + settings.fees.protectionFeePercentage) / 100 * 100).toFixed(2)} in fees
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'features' && (
              <div className="space-y-6">
                <h3 className="text-lg font-semibold text-white">Platform Features</h3>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {Object.entries(settings.features).map(([key, value]) => (
                    <div key={key} className="flex items-center justify-between p-4 bg-gray-800/30 rounded-lg">
                      <div>
                        <div className="text-white font-medium capitalize">
                          {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                        </div>
                        <div className="text-sm text-gray-400">
                          {key === 'enableGarageSales' && 'Allow users to create garage sale events'}
                          {key === 'enableBubbles' && 'Enable Brrow Bubbles social features'}
                          {key === 'enableMessaging' && 'Allow users to message each other'}
                          {key === 'enableReviews' && 'Enable rating and review system'}
                          {key === 'enableFavorites' && 'Allow users to favorite listings'}
                          {key === 'enableAnalytics' && 'Track platform analytics and metrics'}
                        </div>
                      </div>
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input
                          type="checkbox"
                          checked={value}
                          onChange={(e) => updateSetting('features', key, e.target.checked)}
                          className="sr-only peer"
                        />
                        <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                      </label>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Add other tab content here for security, notifications, integrations */}
            {activeTab === 'security' && (
              <div className="space-y-6">
                <h3 className="text-lg font-semibold text-white">Security Settings</h3>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Session Timeout (minutes)
                    </label>
                    <input
                      type="number"
                      value={settings.security.sessionTimeoutMinutes}
                      onChange={(e) => updateSetting('security', 'sessionTimeoutMinutes', parseInt(e.target.value))}
                      className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Max Login Attempts
                    </label>
                    <input
                      type="number"
                      value={settings.security.maxLoginAttempts}
                      onChange={(e) => updateSetting('security', 'maxLoginAttempts', parseInt(e.target.value))}
                      className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Password Minimum Length
                    </label>
                    <input
                      type="number"
                      value={settings.security.passwordMinLength}
                      onChange={(e) => updateSetting('security', 'passwordMinLength', parseInt(e.target.value))}
                      className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>

                <div className="space-y-4">
                  {Object.entries(settings.security).filter(([key]) => typeof settings.security[key as keyof typeof settings.security] === 'boolean').map(([key, value]) => (
                    <div key={key} className="flex items-center justify-between p-4 bg-gray-800/30 rounded-lg">
                      <div>
                        <div className="text-white font-medium capitalize">
                          {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                        </div>
                        <div className="text-sm text-gray-400">
                          {key === 'requireEmailVerification' && 'Require users to verify their email address'}
                          {key === 'requirePhoneVerification' && 'Require users to verify their phone number'}
                          {key === 'enableTwoFactorAuth' && 'Enable two-factor authentication option'}
                        </div>
                      </div>
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input
                          type="checkbox"
                          checked={value as boolean}
                          onChange={(e) => updateSetting('security', key, e.target.checked)}
                          className="sr-only peer"
                        />
                        <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                      </label>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {activeTab === 'notifications' && (
              <div className="space-y-6">
                <h3 className="text-lg font-semibold text-white">Notification Settings</h3>

                <div className="space-y-4">
                  {Object.entries(settings.notifications).map(([key, value]) => (
                    <div key={key} className="flex items-center justify-between p-4 bg-gray-800/30 rounded-lg">
                      <div>
                        <div className="text-white font-medium capitalize">
                          {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                        </div>
                        <div className="text-sm text-gray-400">
                          {key === 'emailNotifications' && 'Send email notifications to users'}
                          {key === 'pushNotifications' && 'Send push notifications to mobile devices'}
                          {key === 'smsNotifications' && 'Send SMS notifications via Twilio'}
                          {key === 'marketingEmails' && 'Send marketing and promotional emails'}
                          {key === 'systemAlerts' && 'Send system alerts and updates'}
                        </div>
                      </div>
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input
                          type="checkbox"
                          checked={value}
                          onChange={(e) => updateSetting('notifications', key, e.target.checked)}
                          className="sr-only peer"
                        />
                        <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                      </label>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {activeTab === 'integrations' && (
              <div className="space-y-6">
                <h3 className="text-lg font-semibold text-white">Third-party Integrations</h3>

                {/* Stripe Integration */}
                <div className="bg-gray-800/30 rounded-lg p-6">
                  <div className="flex items-center justify-between mb-4">
                    <h4 className="text-white font-medium">Stripe Payment Processing</h4>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={settings.integrations.stripeEnabled}
                        onChange={(e) => updateSetting('integrations', 'stripeEnabled', e.target.checked)}
                        className="sr-only peer"
                      />
                      <div className="w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                  </div>

                  {settings.integrations.stripeEnabled && (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-300 mb-2">
                          Publishable Key
                        </label>
                        <input
                          type="text"
                          value={settings.integrations.stripePublishableKey}
                          onChange={(e) => updateSetting('integrations', 'stripePublishableKey', e.target.value)}
                          className="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                          placeholder="pk_test_..."
                        />
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-300 mb-2">
                          Secret Key
                        </label>
                        <div className="relative">
                          <input
                            type={showSecrets.stripeSecret ? 'text' : 'password'}
                            value={settings.integrations.stripeSecretKey}
                            onChange={(e) => updateSetting('integrations', 'stripeSecretKey', e.target.value)}
                            className="w-full px-3 py-2 pr-10 bg-gray-800 border border-gray-700 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                            placeholder="sk_test_..."
                          />
                          <button
                            type="button"
                            onClick={() => toggleSecret('stripeSecret')}
                            className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-300"
                          >
                            {showSecrets.stripeSecret ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                          </button>
                        </div>
                      </div>
                    </div>
                  )}
                </div>

                {/* Similar sections for Twilio and Email can be added here */}
              </div>
            )}
          </div>
        </div>
      </motion.div>
    </div>
  );
}