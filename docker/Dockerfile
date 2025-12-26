FROM node:18-alpine

# Set working directory inside container
WORKDIR /app

# Copy package files first (for dependency install)
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy entire project into container
COPY . .

# Run entrypoint script when container starts
CMD ["sh", "./docker/entrypoint.sh"]
