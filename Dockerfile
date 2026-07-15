FROM mcr.microsoft.com/playwright:v1.39.0-jammy
RUN npm install -g \
    netlify-cli@17.37.2 \
    serve@14.2.3 node-jq@2.3.5


