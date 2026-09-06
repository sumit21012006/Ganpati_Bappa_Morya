import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

const DB_PATH = path.join(process.cwd(), 'data', 'users.json');

function getUsers() {
  try {
    if (!fs.existsSync(DB_PATH)) {
      return [];
    }
    const fileData = fs.readFileSync(DB_PATH, 'utf-8');
    const parsed = JSON.parse(fileData);
    if (Array.isArray(parsed)) {
      return parsed;
    }
    const citizens = Array.isArray(parsed.citizens) ? parsed.citizens : [];
    const controllers = Array.isArray(parsed.controllers) ? parsed.controllers : [];
    return [...citizens, ...controllers];
  } catch (error) {
    console.error('Error reading users database:', error);
    return [];
  }
}

export async function POST(req: NextRequest) {
  try {
    const { identifier, password, role } = await req.json();

    if (!identifier || !password || !role) {
      return NextResponse.json({ error: 'Missing credentials' }, { status: 400 });
    }

    const users = getUsers();
    const cleanId = identifier.trim().toLowerCase();

    const found = users.find(
      (u: any) =>
        u.role === role &&
        (u.email?.toLowerCase() === cleanId ||
          u.mobile === cleanId ||
          u.badgeId?.toLowerCase() === cleanId)
    );

    if (!found) {
      return NextResponse.json(
        { error: `No ${role.toLowerCase()} account found matching '${identifier}'` },
        { status: 404 }
      );
    }

    if (found.passwordHash !== password) {
      return NextResponse.json({ error: 'Invalid password credential' }, { status: 401 });
    }

    const { passwordHash, ...safeUser } = found;
    return NextResponse.json({ user: safeUser, success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message || 'Authentication error' }, { status: 500 });
  }
}
