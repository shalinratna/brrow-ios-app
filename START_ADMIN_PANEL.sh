#!/bin/bash

# Shaiitech Founder Panel Startup Script
# This script starts both the backend server and admin panel

echo "🚀 ═══════════════════════════════════════════════════════"
echo "   SHAIITECH FOUNDER PANEL - COMPREHENSIVE ADMIN SYSTEM"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        return 0
    else
        return 1
    fi
}

# Kill existing processes on ports
echo -e "${YELLOW}🔧 Checking for existing processes...${NC}"
if check_port 3001; then
    echo -e "${YELLOW}   Killing process on port 3001...${NC}"
    lsof -ti:3001 | xargs kill -9 2>/dev/null
fi
if check_port 3000; then
    echo -e "${YELLOW}   Killing process on port 3000...${NC}"
    lsof -ti:3000 | xargs kill -9 2>/dev/null
fi

# Start backend server
echo -e "\n${BLUE}📦 Starting Backend Server...${NC}"
cd brrow-backend
npm start > backend.log 2>&1 &
BACKEND_PID=$!
echo -e "${GREEN}   ✓ Backend started (PID: $BACKEND_PID)${NC}"

# Wait for backend to be ready
echo -e "${BLUE}⏳ Waiting for backend to initialize...${NC}"
sleep 5

# Check if backend is running
if check_port 3001; then
    echo -e "${GREEN}   ✓ Backend is running on http://localhost:3001${NC}"
else
    echo -e "${RED}   ✗ Backend failed to start. Check backend.log for details${NC}"
    exit 1
fi

# Start admin panel
echo -e "\n${BLUE}🎨 Starting Admin Panel...${NC}"
cd ../brrow-admin
npm run dev > admin.log 2>&1 &
ADMIN_PID=$!
echo -e "${GREEN}   ✓ Admin panel started (PID: $ADMIN_PID)${NC}"

# Wait for admin panel to be ready
echo -e "${BLUE}⏳ Waiting for admin panel to initialize...${NC}"
sleep 5

# Check if admin panel is running
if check_port 3000; then
    echo -e "${GREEN}   ✓ Admin panel is running on http://localhost:3000${NC}"
else
    echo -e "${RED}   ✗ Admin panel failed to start. Check admin.log for details${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ SHAIITECH FOUNDER PANEL IS READY!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📊 Admin Dashboard:${NC} http://localhost:3000"
echo -e "${BLUE}🔧 Backend API:${NC} http://localhost:3001"
echo -e "${BLUE}🔌 WebSocket:${NC} ws://localhost:3001"
echo ""
echo -e "${YELLOW}📝 Default Admin Credentials:${NC}"
echo -e "   Email: admin@shaiitech.com"
echo -e "   Password: Shaiitech2024Admin!"
echo ""
echo -e "${YELLOW}📋 Features Available:${NC}"
echo -e "   • Real-time analytics dashboard"
echo -e "   • User management system"
echo -e "   • Listing moderation tools"
echo -e "   • Server health monitoring"
echo -e "   • WebSocket live updates"
echo -e "   • Developer tools & logs"
echo ""
echo -e "${YELLOW}🛑 To stop all services:${NC}"
echo -e "   Press Ctrl+C or run: kill $BACKEND_PID $ADMIN_PID"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"

# Keep script running and handle shutdown
trap "echo -e '\n${YELLOW}Shutting down services...${NC}'; kill $BACKEND_PID $ADMIN_PID 2>/dev/null; exit" INT

# Monitor processes
while true; do
    if ! kill -0 $BACKEND_PID 2>/dev/null; then
        echo -e "${RED}⚠️  Backend server stopped unexpectedly${NC}"
        kill $ADMIN_PID 2>/dev/null
        exit 1
    fi
    if ! kill -0 $ADMIN_PID 2>/dev/null; then
        echo -e "${RED}⚠️  Admin panel stopped unexpectedly${NC}"
        kill $BACKEND_PID 2>/dev/null
        exit 1
    fi
    sleep 10
done