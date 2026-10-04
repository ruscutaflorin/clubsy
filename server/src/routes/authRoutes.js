import express from 'express';
import { body, query } from 'express-validator';
import { changePassword, checkUsernameAvailable, deleteMyAccount, exportMyData, getCurrentUser, signIn, signUp, updateMyProfile } from '../controllers/authController.js';
import { authMiddleware } from '../middlewares/authMiddleware.js';
import { authLimiter, usernameCheckLimiter } from '../middlewares/rateLimiters.js';

const router = express.Router();

const signUpValidation = [
  body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('acceptTerms').equals('true').withMessage('You must accept the Terms and Privacy Policy'),
  body('ageConfirmed').equals('true').withMessage('You must confirm you are 18 or older'),
];

// Usernames are stored lowercase: 3-20 characters of a-z, 0-9 and _.
const usernameRule = (chain) =>
  chain
    .trim()
    .toLowerCase()
    .matches(/^[a-z0-9_]{3,20}$/)
    .withMessage('Username must be 3-20 characters: letters, digits or _');

const signInValidation = [
  body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required'),
];

// Sign up
router.post('/signup', authLimiter, signUpValidation, signUp);

// Sign in
router.post('/signin', authLimiter, signInValidation, signIn);

// Current user
router.get('/me', authMiddleware, getCurrentUser);

// Update my profile: name, username, homeCity (each optional)
router.patch(
  '/me',
  authMiddleware,
  body('name')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ max: 50 })
    .withMessage('Name must be at most 50 characters'),
  usernameRule(body('username').optional()),
  body('homeCity')
    .optional()
    .isString()
    .trim()
    .isLength({ max: 80 })
    .withMessage('Home city must be at most 80 characters'),
  updateMyProfile
);

// Is this username free? (live check in the edit form)
router.get(
  '/username-available',
  authMiddleware,
  usernameCheckLimiter,
  usernameRule(query('u')),
  checkUsernameAvailable
);

// Download my data (GDPR export)
router.get('/me/export', authMiddleware, exportMyData);

// Change my password
router.post(
  '/me/password',
  authMiddleware,
  authLimiter,
  body('currentPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  changePassword
);

// Delete my account and all my check-ins
router.delete(
  '/me',
  authMiddleware,
  body('password').notEmpty().withMessage('Password is required'),
  deleteMyAccount
);

export default router;