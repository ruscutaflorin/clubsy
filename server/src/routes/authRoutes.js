import express from 'express';
import { signIn, signUp } from '../controllers/authController.js';

const router = express.Router();

// Sign up
router.post('/signup', signUp);

// Sign in
router.post('/signin', signIn);

export default router; 