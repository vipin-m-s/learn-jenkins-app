FROM mcr.microsoft.com/playwright:v1.39.0-jammy
RUN npm install -g \
    netlify-cli@17.37.2 \
    serve@14.2.3
RUN apt update && apt install jq -y 


