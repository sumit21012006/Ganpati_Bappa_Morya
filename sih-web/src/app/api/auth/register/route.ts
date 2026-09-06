import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

const DB_PATH = path.join(process.cwd(), 'data', 'users.json');

interface UserDatabaseSchema {
  citizens: any[];
  controllers: any[];
}

function getUserDb(): UserDatabaseSchema {
  try {
    if (!fs.existsSync(DB_PATH)) {
      return { citizens: [], controllers: [] };
    }
    const fileData = fs.readFileSync(DB_PATH, 'utf-8');
    const parsed = JSON.parse(fileData);
    if (Array.isArray(parsed)) {
      return {
        citizens: parsed.filter((u: any) => u.role === 'CITIZEN'),
        controllers: parsed.filter((u: any) => u.role === 'CONTROLLER'),
      };
    }
    return {
      citizens: Array.isArray(parsed.citizens) ? parsed.citizens : [],
      controllers: Array.isArray(parsed.controllers) ? parsed.controllers : [],
    };
  } catch (error) {
    return { citizens: [], controllers: [] };
  }
}

function saveUserDb(db: UserDatabaseSchema) {
  const dir = path.dirname(DB_PATH);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(DB_PATH, JSON.stringify(db, null, 2), 'utf-8');
}

export async function POST(req: NextRequest) {
  try {
    const data = await req.json();

    if (!data.name || !data.email || !data.password || !data.role) {
      return NextResponse.json({ error: 'Missing required registration fields' }, { status: 400 });
    }

    const db = getUserDb();
    const allUsers = [...db.citizens, ...db.controllers];

    const existing = allUsers.find(
      (u: any) =>
        u.email.toLowerCase() === data.email.toLowerCase() ||
        (data.mobile && u.mobile === data.mobile) ||
        (data.badgeId && u.badgeId === data.badgeId)
    );

    if (existing) {
      return NextResponse.json(
        { error: 'User account already exists with these credentials' },
        { status: 409 }
      );
    }

    const newUser = {
      id: `usr_${data.role.toLowerCase()}_${Date.now()}`,
      name: data.name,
      email: data.email,
      mobile: data.mobile || null,
      badgeId: data.badgeId || null,
      role: data.role,
      rewardPoints: data.role === 'CITIZEN' ? 500 : 0,
      upiVpa: data.upiVpa || (data.role === 'CITIZEN' ? `${data.name.toLowerCase().replace(/\s+/g, '.')}@upi` : null),
      passwordHash: data.password,
      createdAt: new Date().toISOString(),
    };

    if (data.role === 'CONTROLLER') {
      db.controllers.push(newUser);
    } else {
      db.citizens.push(newUser);
    }

    saveUserDb(db);

    const { passwordHash, ...safeUser } = newUser;
    return NextResponse.json({ user: safeUser, success: true }, { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ error: error.message || 'Registration error' }, { status: 500 });
  }
}
