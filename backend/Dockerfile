# Use the official Node.js LTS image as the base image
FROM node:16

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json to the working directory
COPY package.json ./

# Install app dependencies
RUN npm install

# Copy the rest of the application code to the working directory
COPY . .

# Expose the port that your application will run on
EXPOSE 5000

# Set environment variables (adjust as needed)
ENV PORT=5000
ENV MONGO_URI=mongodb://mongodb-service:27017/mydatabase

# Start the application
CMD ["node", "index.js"]
