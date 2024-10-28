const mongoose = require('mongoose');
require('dotenv').config();

const MONGO_URI = process.env.MONGO_URI || 'mongodb://mongodb-service:27017/mydatabase';

// Connecting to MongoDB
mongoose.connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => {
    console.log('Connected to MongoDB');
    
    // Create an initial collection if needed
    const TestSchema = new mongoose.Schema({ name: String });
    const Test = mongoose.model('Test', TestSchema);

    // Insert a document to trigger database creation
    Test.create({ name: 'Initial Entry' }).then(() => console.log('Database initialized with a collection'));
  })
  .catch(err => console.error('MongoDB connection error:', err));
  
app.get('/', (req, res) => res.send('Hello from the Backend!'));
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));