const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const apiRoutes = require('./routes');
const { notFound, errorHandler } = require('./middleware/error.middleware');

const app = express();

app.use(helmet());
app.use(cors());
app.use(morgan('dev'));

// Middleware to capture raw body for webhook signature verification
app.use(express.json({ verify: (req, res, buf, encoding) => {
  req.rawBody = buf.toString(encoding || 'utf8');
} }));

app.use('/api', apiRoutes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
