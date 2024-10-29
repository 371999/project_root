# Use the official Node.js 14 image as the base image
FROM node:14 AS build

# Set the working directory in the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Clean npm cache and install dependencies
RUN npm cache clean --force && npm install

# Copy the rest of the application code
COPY . .

# Ensure public/index.html exists
# Increase memory limit for Node.js during build if needed
ENV NODE_OPTIONS="--max-old-space-size=2048"

# Build the React application
RUN npm run build --verbose

# Use nginx to serve the build
FROM nginx:alpine

# Copy the React build files to the nginx HTML folder
COPY --from=build /app/build /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
