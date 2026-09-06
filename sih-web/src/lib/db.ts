import { AuthUser, UserRole } from '@/types';

export interface StoredUser extends AuthUser {
  passwordHash: string;
}

const DEFAULT_USERS: StoredUser[] = [
  {
    id: 'usr_cit_01',
    name: 'Arjun Suresh Sharma',
    email: 'citizen@gov.in',
    mobile: '9845012345',
    role: 'CITIZEN',
    rewardPoints: 2750,
    upiVpa: 'arjun.sharma@okaxis',
    passwordHash: 'password123',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'usr_ctrl_01',
    name: 'Shri R.K. Singh',
    email: 'controller@gov.in',
    badgeId: 'MH-LM-412',
    role: 'CONTROLLER',
    rewardPoints: 0,
    passwordHash: 'password123',
    createdAt: new Date().toISOString(),
  },
];

class AuthDatabase {
  private getStorage(): StoredUser[] {
    if (typeof window === 'undefined') return DEFAULT_USERS;
    try {
      const data = localStorage.getItem('legal_metrology_users');
      if (!data) {
        localStorage.setItem('legal_metrology_users', JSON.stringify(DEFAULT_USERS));
        return DEFAULT_USERS;
      }
      return JSON.parse(data);
    } catch {
      return DEFAULT_USERS;
    }
  }

  private saveStorage(users: StoredUser[]) {
    if (typeof window !== 'undefined') {
      try {
        localStorage.setItem('legal_metrology_users', JSON.stringify(users));
      } catch (e) {
        console.error('Failed to write to local storage:', e);
      }
    }
  }

  public register(data: {
    name: string;
    email: string;
    mobile?: string;
    badgeId?: string;
    password: string;
    role: UserRole;
    upiVpa?: string;
  }): AuthUser {
    const users = this.getStorage();
    const existing = users.find(
      (u) =>
        u.email.toLowerCase() === data.email.toLowerCase() ||
        (data.mobile && u.mobile === data.mobile) ||
        (data.badgeId && u.badgeId === data.badgeId)
    );

    if (existing) {
      throw new Error('User account already exists with these credentials.');
    }

    const newUser: StoredUser = {
      id: `usr_${data.role.toLowerCase()}_${Date.now()}`,
      name: data.name,
      email: data.email,
      mobile: data.mobile,
      badgeId: data.badgeId,
      role: data.role,
      rewardPoints: data.role === 'CITIZEN' ? 500 : 0,
      upiVpa: data.upiVpa || (data.role === 'CITIZEN' ? `${data.name.toLowerCase().replace(/\s+/g, '.')}@upi` : undefined),
      passwordHash: data.password,
      createdAt: new Date().toISOString(),
    };

    users.push(newUser);
    this.saveStorage(users);

    // Asynchronously persist new user to server disk file (data/users.json)
    if (typeof window !== 'undefined') {
      fetch('/api/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: data.name,
          email: data.email,
          mobile: data.mobile,
          badgeId: data.badgeId,
          password: data.password,
          role: data.role,
          upiVpa: data.upiVpa,
        }),
      }).catch((err) => console.error('Disk persistence to users.json failed:', err));
    }

    const { passwordHash, ...safeUser } = newUser;
    return safeUser;
  }

  public login(identifier: string, password: string, role: UserRole): AuthUser {
    const users = this.getStorage();
    const cleanId = identifier.trim().toLowerCase();

    const found = users.find(
      (u) =>
        u.role === role &&
        (u.email.toLowerCase() === cleanId ||
          (u.mobile && u.mobile === cleanId) ||
          (u.badgeId && u.badgeId.toLowerCase() === cleanId))
    );

    if (!found) {
      throw new Error(`No ${role.toLowerCase()} account found matching '${identifier}'.`);
    }

    if (found.passwordHash !== password) {
      throw new Error('Invalid password credential.');
    }

    const { passwordHash, ...safeUser } = found;
    return safeUser;
  }
}

export const authDb = new AuthDatabase();
