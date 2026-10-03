import express from 'express';
import { body } from 'express-validator';
import { changePassword, deleteMyAccount, exportMyData, getCurrentUser, signIn, signUp, updateMyProfile } from '../controllers/authController.js';
import { authMiddleware } from '../middlewares/authMiddleware.js';
import { authLimiter } from '../middlewares/rateLimiters.js';

const router = express.Router();

export const signUpValidation = [
  body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('name').trim().notEmpty().withMessage('Name is required'),
];

export const signInValidation = [
  body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required'),
];

// Sign up
router.post('/signup', authLimiter, signUpValidation, signUp);

// Sign in
router.post('/signin', authLimiter, signInValidation, signIn);

// Current user
router.get('/me', authMiddleware, getCurrentUser);

// Change my display name
router.patch(
  '/me',
  authMiddleware,
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ max: 50 })
    .withMessage('Name must be at most 50 characters'),
  updateMyProfile
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