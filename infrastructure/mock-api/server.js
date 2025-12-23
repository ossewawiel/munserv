/**
 * MunServ Mock API Server
 * 
 * Provides mock endpoints for MVP development of mobile and web apps.
 * See specs/MVP_Development_Guide.md for API contract details.
 */

const express = require('express');
const cors = require('cors');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// Multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = './uploads';
    if (!fs.existsSync(dir)) fs.mkdirSync(dir);
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, `${uuidv4()}${path.extname(file.originalname)}`);
  }
});
const upload = multer({ storage });

// Load mock data
let sectors = require('./data/sectors.json');
let members = require('./data/members.json');
let issues = require('./data/issues.json');
let admins = require('./data/admins.json');

// In-memory OTP storage (would be Redis in production)
const otpStore = new Map();
const tempTokenStore = new Map();

// Helper: Generate mock JWT
const generateToken = (payload) => {
  // In real app, this would be a proper JWT
  const token = Buffer.from(JSON.stringify({ ...payload, exp: Date.now() + 86400000 })).toString('base64');
  return `mock.${token}.signature`;
};

// Helper: Verify mock token
const verifyToken = (req, res, next) => {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) {
    return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Missing token' } });
  }
  // For mock, just check it exists
  req.token = auth.split(' ')[1];
  next();
};

// ============================================================================
// AUTH ENDPOINTS
// ============================================================================

// POST /api/v1/auth/register - Request OTP
app.post('/api/v1/auth/register', (req, res) => {
  const { phoneNumber } = req.body;
  
  if (!phoneNumber || !phoneNumber.match(/^\+\d{10,15}$/)) {
    return res.status(400).json({
      error: { code: 'VALIDATION_ERROR', message: 'Invalid phone number format' }
    });
  }
  
  // Generate mock OTP (always 123456 for testing)
  const otp = '123456';
  otpStore.set(phoneNumber, { otp, expiresAt: Date.now() + 300000 });
  
  console.log(`[AUTH] OTP for ${phoneNumber}: ${otp}`);
  
  res.json({ message: 'OTP sent', expiresInSeconds: 300 });
});

// POST /api/v1/auth/verify-otp
app.post('/api/v1/auth/verify-otp', (req, res) => {
  const { phoneNumber, otp } = req.body;
  
  const stored = otpStore.get(phoneNumber);
  if (!stored || stored.otp !== otp) {
    return res.status(401).json({
      error: { code: 'UNAUTHORIZED', message: 'Invalid OTP' }
    });
  }
  
  otpStore.delete(phoneNumber);
  
  // Check if existing member
  const member = members.find(m => m.phoneNumber === phoneNumber);
  
  if (member) {
    const sector = sectors.find(s => s.id === member.sectorId);
    return res.json({
      status: 'existing_user',
      tokens: {
        accessToken: generateToken({ id: member.id, type: 'member' }),
        refreshToken: generateToken({ id: member.id, type: 'refresh' }),
        expiresAt: new Date(Date.now() + 86400000).toISOString()
      },
      profile: {
        member: { id: member.id, phoneNumber: member.phoneNumber, displayName: member.displayName, sectorId: member.sectorId, createdAt: member.createdAt },
        sector
      }
    });
  }
  
  // New user - return temp token
  const tempToken = uuidv4();
  tempTokenStore.set(tempToken, { phoneNumber, expiresAt: Date.now() + 600000 });
  
  res.json({ status: 'new_user', tempToken });
});

// POST /api/v1/auth/complete-registration
app.post('/api/v1/auth/complete-registration', (req, res) => {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) {
    return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Missing temp token' } });
  }
  
  const tempToken = auth.split(' ')[1];
  const stored = tempTokenStore.get(tempToken);
  
  if (!stored) {
    return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Invalid or expired temp token' } });
  }
  
  const { displayName, pin, sectorId } = req.body;
  
  if (!displayName || !pin || !sectorId) {
    return res.status(400).json({
      error: { code: 'VALIDATION_ERROR', message: 'Missing required fields' }
    });
  }
  
  const sector = sectors.find(s => s.id === sectorId);
  if (!sector) {
    return res.status(400).json({
      error: { code: 'VALIDATION_ERROR', message: 'Invalid sector' }
    });
  }
  
  // Create new member
  const newMember = {
    id: uuidv4(),
    phoneNumber: stored.phoneNumber,
    displayName,
    sectorId,
    pin,
    createdAt: new Date().toISOString()
  };
  
  members.push(newMember);
  tempTokenStore.delete(tempToken);
  
  res.status(201).json({
    tokens: {
      accessToken: generateToken({ id: newMember.id, type: 'member' }),
      refreshToken: generateToken({ id: newMember.id, type: 'refresh' }),
      expiresAt: new Date(Date.now() + 86400000).toISOString()
    },
    profile: {
      member: { id: newMember.id, phoneNumber: newMember.phoneNumber, displayName: newMember.displayName, sectorId: newMember.sectorId, createdAt: newMember.createdAt },
      sector
    }
  });
});

// POST /api/v1/auth/login
app.post('/api/v1/auth/login', (req, res) => {
  const { phoneNumber, pin } = req.body;
  
  const member = members.find(m => m.phoneNumber === phoneNumber);
  
  if (!member || member.pin !== pin) {
    return res.status(401).json({
      error: { code: 'UNAUTHORIZED', message: 'Invalid credentials' }
    });
  }
  
  const sector = sectors.find(s => s.id === member.sectorId);
  
  res.json({
    tokens: {
      accessToken: generateToken({ id: member.id, type: 'member' }),
      refreshToken: generateToken({ id: member.id, type: 'refresh' }),
      expiresAt: new Date(Date.now() + 86400000).toISOString()
    },
    profile: {
      member: { id: member.id, phoneNumber: member.phoneNumber, displayName: member.displayName, sectorId: member.sectorId, createdAt: member.createdAt },
      sector
    }
  });
});

// POST /api/v1/auth/admin/login
app.post('/api/v1/auth/admin/login', (req, res) => {
  const { email, password } = req.body;
  
  const admin = admins.find(a => a.email === email);
  
  if (!admin || admin.password !== password) {
    return res.status(401).json({
      error: { code: 'UNAUTHORIZED', message: 'Invalid credentials' }
    });
  }
  
  const sector = sectors.find(s => s.id === admin.sectorId);
  
  res.json({
    tokens: {
      accessToken: generateToken({ id: admin.id, type: 'admin', role: admin.role }),
      refreshToken: generateToken({ id: admin.id, type: 'refresh' }),
      expiresAt: new Date(Date.now() + 86400000).toISOString()
    },
    profile: {
      admin: { id: admin.id, email: admin.email, displayName: admin.displayName, sectorId: admin.sectorId, role: admin.role },
      sector
    }
  });
});

// POST /api/v1/auth/refresh
app.post('/api/v1/auth/refresh', (req, res) => {
  const { refreshToken } = req.body;
  
  if (!refreshToken) {
    return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Missing refresh token' } });
  }
  
  // For mock, just generate new tokens
  res.json({
    tokens: {
      accessToken: generateToken({ type: 'member' }),
      refreshToken: generateToken({ type: 'refresh' }),
      expiresAt: new Date(Date.now() + 86400000).toISOString()
    }
  });
});

// ============================================================================
// ISSUES ENDPOINTS
// ============================================================================

// GET /api/v1/issues
app.get('/api/v1/issues', verifyToken, (req, res) => {
  const { sectorId, state, type, page = 1, limit = 20, sortBy = 'heat' } = req.query;
  
  let filtered = [...issues];
  
  if (sectorId) {
    filtered = filtered.filter(i => i.sectorId === sectorId);
  }
  if (state) {
    filtered = filtered.filter(i => i.state === state);
  }
  if (type) {
    filtered = filtered.filter(i => i.type === type);
  }
  
  // Sort
  if (sortBy === 'heat') {
    filtered.sort((a, b) => b.heat - a.heat);
  } else if (sortBy === 'createdAt') {
    filtered.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  }
  
  // Paginate
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + parseInt(limit);
  const paginated = filtered.slice(startIndex, endIndex);
  
  // Transform to summary
  const items = paginated.map(i => ({
    id: i.id,
    type: i.type,
    state: i.state,
    location: i.location,
    heat: i.heat,
    thumbnailUrl: i.photoUrls[0],
    createdAt: i.createdAt
  }));
  
  res.json({
    items,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      totalItems: filtered.length,
      totalPages: Math.ceil(filtered.length / limit)
    }
  });
});

// GET /api/v1/issues/mine
app.get('/api/v1/issues/mine', verifyToken, (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  
  // For mock, return issues from first member
  const reporterId = members[0].id;
  const filtered = issues.filter(i => i.reporterId === reporterId);
  
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + parseInt(limit);
  const paginated = filtered.slice(startIndex, endIndex);
  
  const items = paginated.map(i => ({
    id: i.id,
    type: i.type,
    state: i.state,
    location: i.location,
    heat: i.heat,
    thumbnailUrl: i.photoUrls[0],
    createdAt: i.createdAt
  }));
  
  res.json({
    items,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      totalItems: filtered.length,
      totalPages: Math.ceil(filtered.length / limit)
    }
  });
});

// GET /api/v1/issues/:id
app.get('/api/v1/issues/:id', verifyToken, (req, res) => {
  const issue = issues.find(i => i.id === req.params.id);
  
  if (!issue) {
    return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Issue not found' } });
  }
  
  res.json(issue);
});

// POST /api/v1/issues
app.post('/api/v1/issues', verifyToken, upload.array('photos', 5), (req, res) => {
  const { type, latitude, longitude, description } = req.body;
  
  if (!type || !latitude || !longitude) {
    return res.status(400).json({
      error: { code: 'VALIDATION_ERROR', message: 'Missing required fields' }
    });
  }
  
  if (!req.files || req.files.length === 0) {
    return res.status(400).json({
      error: { code: 'VALIDATION_ERROR', message: 'At least one photo is required' }
    });
  }
  
  const photoUrls = req.files.map(f => `http://localhost:${PORT}/uploads/${f.filename}`);
  
  const newIssue = {
    id: uuidv4(),
    type,
    state: 'reported',
    location: { latitude: parseFloat(latitude), longitude: parseFloat(longitude) },
    address: null,
    description: description || null,
    heat: 10,
    photoUrls,
    sectorId: sectors[0].id,
    reporterId: members[0].id,
    reportCount: 1,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    stateHistory: [
      {
        state: 'reported',
        changedAt: new Date().toISOString(),
        changedBy: null,
        note: null
      }
    ]
  };
  
  issues.push(newIssue);
  
  console.log(`[ISSUES] New issue created: ${newIssue.id}`);
  
  res.status(201).json({
    id: newIssue.id,
    type: newIssue.type,
    state: newIssue.state,
    location: newIssue.location,
    heat: newIssue.heat,
    photoUrls: newIssue.photoUrls,
    createdAt: newIssue.createdAt
  });
});

// PATCH /api/v1/issues/:id/state
app.patch('/api/v1/issues/:id/state', verifyToken, (req, res) => {
  const { state, note } = req.body;
  
  const issue = issues.find(i => i.id === req.params.id);
  
  if (!issue) {
    return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Issue not found' } });
  }
  
  const validStates = ['reported', 'confirmed', 'in_progress', 'fixed', 'rejected'];
  if (!validStates.includes(state)) {
    return res.status(400).json({
      error: { code: 'VALIDATION_ERROR', message: 'Invalid state' }
    });
  }
  
  // Update issue
  issue.state = state;
  issue.updatedAt = new Date().toISOString();
  issue.stateHistory.push({
    state,
    changedAt: issue.updatedAt,
    changedBy: admins[0].id,
    note: note || null
  });
  
  // Update heat (simplified)
  if (state === 'fixed' || state === 'rejected') {
    issue.heat = 0;
  }
  
  console.log(`[ISSUES] Issue ${issue.id} state changed to ${state}`);
  
  res.json({
    id: issue.id,
    state: issue.state,
    updatedAt: issue.updatedAt
  });
});

// ============================================================================
// SECTORS ENDPOINTS
// ============================================================================

// GET /api/v1/sectors
app.get('/api/v1/sectors', (req, res) => {
  res.json({ items: sectors });
});

// ============================================================================
// ADMIN ENDPOINTS
// ============================================================================

// GET /api/v1/admin/dashboard
app.get('/api/v1/admin/dashboard', verifyToken, (req, res) => {
  const sectorId = sectors[0].id;
  const sectorIssues = issues.filter(i => i.sectorId === sectorId);
  
  const byState = {
    reported: sectorIssues.filter(i => i.state === 'reported').length,
    confirmed: sectorIssues.filter(i => i.state === 'confirmed').length,
    in_progress: sectorIssues.filter(i => i.state === 'in_progress').length,
    fixed: sectorIssues.filter(i => i.state === 'fixed').length,
    rejected: sectorIssues.filter(i => i.state === 'rejected').length
  };
  
  const byType = {};
  sectorIssues.forEach(i => {
    byType[i.type] = (byType[i.type] || 0) + 1;
  });
  
  const openIssues = sectorIssues.filter(i => !['fixed', 'rejected'].includes(i.state));
  
  // Calculate avg resolution time (mock)
  const avgResolutionDays = 4.5;
  
  // Issues this week (mock)
  const reportedThisWeek = 12;
  
  res.json({
    sectorId,
    sectorName: sectors[0].name,
    stats: {
      totalOpen: openIssues.length,
      byState,
      byType,
      avgResolutionDays,
      reportedThisWeek
    }
  });
});

// GET /api/v1/admin/reports/heat
app.get('/api/v1/admin/reports/heat', verifyToken, (req, res) => {
  const { limit = 20 } = req.query;
  
  const openIssues = issues
    .filter(i => !['fixed', 'rejected'].includes(i.state))
    .sort((a, b) => b.heat - a.heat)
    .slice(0, parseInt(limit));
  
  const items = openIssues.map(i => {
    const daysOpen = Math.floor((Date.now() - new Date(i.createdAt)) / (1000 * 60 * 60 * 24));
    return {
      id: i.id,
      type: i.type,
      state: i.state,
      heat: i.heat,
      daysOpen,
      reportCount: i.reportCount,
      location: i.location,
      thumbnailUrl: i.photoUrls[0]
    };
  });
  
  res.json({
    generatedAt: new Date().toISOString(),
    items
  });
});

// GET /api/v1/admin/members
app.get('/api/v1/admin/members', verifyToken, (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + parseInt(limit);
  const paginated = members.slice(startIndex, endIndex);
  
  const items = paginated.map(m => {
    const issueCount = issues.filter(i => i.reporterId === m.id).length;
    return {
      id: m.id,
      displayName: m.displayName,
      phoneNumber: m.phoneNumber,
      issueCount,
      joinedAt: m.createdAt
    };
  });
  
  res.json({
    items,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      totalItems: members.length,
      totalPages: Math.ceil(members.length / limit)
    }
  });
});

// ============================================================================
// SERVER START
// ============================================================================

app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════════════════╗
║                    MunServ Mock API                           ║
╠═══════════════════════════════════════════════════════════════╣
║  Server running at: http://localhost:${PORT}                    ║
║  API Base URL:      http://localhost:${PORT}/api/v1             ║
╠═══════════════════════════════════════════════════════════════╣
║  Test Credentials:                                            ║
║  ─────────────────                                            ║
║  Member:  +27821234567 / OTP: 123456 / PIN: 1234              ║
║  Admin:   admin@ward42.example.com / admin123                 ║
╠═══════════════════════════════════════════════════════════════╣
║  See specs/MVP_Development_Guide.md for full API contract     ║
╚═══════════════════════════════════════════════════════════════╝
  `);
});
