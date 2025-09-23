import { NextRequest, NextResponse } from 'next/server';
import jwt from 'jsonwebtoken';

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@shaiitech.com';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Shaiitech2024Admin!';
const JWT_SECRET = process.env.JWT_SECRET || 'brrow-secret-key-2024';

export async function POST(req: NextRequest) {
  try {
    const { email, password } = await req.json();

    // Check admin credentials
    if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
      // Generate JWT token
      const token = jwt.sign(
        { 
          id: 'admin-001',
          email,
          role: 'SUPER_ADMIN',
          name: 'Super Admin'
        },
        JWT_SECRET,
        { expiresIn: '7d' }
      );

      return NextResponse.json({
        token,
        user: {
          id: 'admin-001',
          email,
          role: 'SUPER_ADMIN',
          name: 'Super Admin'
        }
      });
    }

    // If not super admin, try backend API for other admin users
    const backendResponse = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });

    if (backendResponse.ok) {
      const data = await backendResponse.json();
      return NextResponse.json(data);
    }

    return NextResponse.json(
      { error: 'Invalid admin credentials' },
      { status: 401 }
    );
  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json(
      { error: 'Authentication failed' },
      { status: 500 }
    );
  }
}