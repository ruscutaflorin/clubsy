import express from 'express';
import { body } from 'express-validator';
import { getCurrentUser, signIn, signUp } from '../controllers/authController.js';
import { authMiddleware } from '../middlewares/authMiddleware.js';

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
router.post('/signup', signUpValidation, signUp);

// Sign in
router.post('/signin', signInValidation, signIn);

// Current user
router.get('/me', authMiddleware, getCurrentUser);

export default router;