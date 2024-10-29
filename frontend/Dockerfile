# Use Node.js 16 as the base image for better compatibility
FROM node:16 AS build

# Set the working directory
WORKDIR /app

# Copy package.json to the working directory
COPY package.json ./

# Clear npm cache and install dependencies with verbose logging
RUN npm cache clean --force && npm install --verbose

# Copy the rest of the application code to the working directory
COPY . .

# Build the React application
RUN npm run build

# Use nginx to serve the build
FROM nginx:alpine

# Copy the React build output to nginx's HTML folder
COPY --from=build /app/build /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
