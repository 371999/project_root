# Use Node.js 16 Alpine as the base image for a smaller footprint
FROM node:16-alpine AS build

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package.json ./

# Install dependencies
RUN npm install --production

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

# Set the command to start nginx
CMD ["nginx", "-g", "daemon off;"]
