# Family Site AI Service

An AI-powered microservice built with FastAPI to enhance the Family Recipe Site with intelligent recipe suggestions and recipe text parsing. This service uses OpenRouter for AI capabilities.

## 📋 Overview

This service provides AI capabilities to the main Family Site application through a RESTful API. It features:

- Recipe suggestions based on available ingredients
- Intelligent parsing of unstructured recipe text
- Dietary preference-based recipe modifications
- Recipe scaling and ingredient substitution recommendations

## 🛠️ Technology Stack

- **FastAPI**: Modern, fast web framework for building APIs
- **OpenRouter API**: For AI-powered recipe analysis and generation
- **Docker**: For containerization and deployment
- **Python 3.11+**: Core programming language

## 🚀 Getting Started

### Prerequisites

- Python 3.11 or higher
- Docker and Docker Compose
- OpenRouter API key

### Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/family-site-ai.git
   cd family-site-ai
   ```

2. Create a virtual environment and install dependencies:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. Create `.env` file with required environment variables:
   ```
   OPENROUTER_API_KEY=your_openrouter_api_key
   OPENROUTER_URL=https://api.openrouter.com/v1
   OPENROUTER_MODEL=your_chosen_model
   OPENROUTER_SITE_URL=your_site_url
   OPENROUTER_APP_NAME=Family Recipe AI
   ENVIRONMENT=development
   ```

4. Run the service locally:
   ```bash
   uvicorn main:app --reload
   ```

5. Visit `http://localhost:8000/docs` to see the Swagger UI documentation.

### Using Docker

1. Build and start the container:
   ```bash
   docker compose up -d
   ```

2. The service will be available at `http://localhost:8000`

## 🔐 Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `OPENROUTER_API_KEY` | OpenRouter API key for AI functionality | Yes | - |
| `OPENROUTER_URL` | OpenRouter API endpoint | No | https://api.openrouter.com/v1 |
| `OPENROUTER_MODEL` | Model to use for AI generation | Yes | - |
| `OPENROUTER_SITE_URL` | Your site URL for request validation | Yes | - |
| `OPENROUTER_APP_NAME` | Your application name | Yes | - |
| `ENVIRONMENT` | Deployment environment (development/production) | No | development |
| `HOST` | Host to bind the server to | No | 0.0.0.0 |
| `PORT` | Port to bind the server to | No | 8000 |
| `ALLOWED_ORIGINS` | Comma-separated list of allowed CORS origins | No | http://localhost:5001,https://family-site.pythonanywhere.com |

## 🤖 OpenRouter Models

This service uses OpenRouter as an API gateway to access various AI models. For the MVP, a free tier model was selected to minimize costs while providing adequate functionality.

### Model Selection

- **Default Model**: The service is configured to use a free tier model for the MVP
- **Model Flexibility**: Any OpenRouter-supported model can be used by simply changing the `OPENROUTER_MODEL` environment variable
- **No Code Changes Required**: The same API key works across all models, making it easy to upgrade or switch models as needed

### Available Models

OpenRouter provides access to various models with different capabilities and pricing:

- Free tier models (limited usage)
- Claude models from Anthropic
- GPT models from OpenAI
- Llama models from Meta
- And many others

Refer to the [OpenRouter documentation](https://openrouter.ai/docs) for the complete list of available models and their capabilities.

## 📊 API Endpoints

### Health Check

```
GET /health
```

Returns the service health status and version information.

### Recipe Suggestions

```
POST /api/ai/recipe-suggestions
```

Generate recipe suggestions based on available ingredients and dietary preferences.

**Request Body:**
```json
{
  "ingredients": ["chicken", "rice", "tomatoes"],
  "dietary_preferences": ["gluten-free"],
  "excluded_ingredients": ["mushrooms"]
}
```

**Response:**
```json
{
  "suggestions": [
    {
      "title": "Chicken and Rice Tomato Bowl",
      "description": "A delicious gluten-free meal with chicken, rice, and fresh tomatoes.",
      "ingredients": [
        {"name": "chicken breast", "quantity": 2.0, "unit": "pieces"},
        {"name": "rice", "quantity": 1.0, "unit": "cup"},
        {"name": "tomatoes", "quantity": 2.0, "unit": "medium"}
      ],
      "instructions": [
        "Cook rice according to package instructions.",
        "Season and cook chicken until internal temperature reaches 165°F.",
        "Dice tomatoes and combine with cooked ingredients."
      ],
      "cooking_time_minutes": 25,
      "preparation_time_minutes": 10,
      "servings": 2,
      "confidence_score": 0.92
    }
  ],
  "processing_time": 1.234
}
```

### Recipe Parsing

```
POST /api/ai/recipe-parsing
```

Parse unstructured recipe text into a structured format.

**Request Body:**
```json
{
  "recipe_text": "Chocolate Chip Cookies\n\nIngredients:\n2 cups flour\n1 cup butter\n1 cup sugar\n2 eggs\n2 cups chocolate chips\n\nInstructions:\nPreheat oven to 350F. Mix all ingredients. Drop spoonfuls onto cookie sheet. Bake for 10-12 minutes."
}
```

**Response:**
```json
{
  "parsed_recipe": {
    "title": "Chocolate Chip Cookies",
    "description": null,
    "ingredients": [
      {"name": "flour", "quantity": 2.0, "unit": "cups"},
      {"name": "butter", "quantity": 1.0, "unit": "cup"},
      {"name": "sugar", "quantity": 1.0, "unit": "cup"},
      {"name": "eggs", "quantity": 2.0, "unit": null},
      {"name": "chocolate chips", "quantity": 2.0, "unit": "cups"}
    ],
    "instructions": [
      "Preheat oven to 350F.",
      "Mix all ingredients.",
      "Drop spoonfuls onto cookie sheet.",
      "Bake for 10-12 minutes."
    ],
    "cooking_time_minutes": 12,
    "preparation_time_minutes": 10,
    "servings": 24
  },
  "processing_time": 0.876
}
```

## 📦 Deployment to DigitalOcean

### Using DigitalOcean App Platform

1. Create a new app on DigitalOcean App Platform
2. Connect your GitHub repository
3. Configure environment variables
4. Deploy the application

### Using DigitalOcean Droplet with Docker

1. Create a Droplet with Docker pre-installed
2. Clone the repository on the Droplet
3. Create `.env` file with production settings
4. Run with Docker Compose:
   ```bash
   docker compose up -d
   ```
5. Set up Nginx as a reverse proxy (recommended)
6. Configure SSL with Let's Encrypt (recommended)

## 🚢 Deployment

### DigitalOcean

The project includes a comprehensive deployment script (`deploy.sh`) that automates the deployment process to DigitalOcean:

1. Build and push Docker image with the correct platform (linux/amd64)
2. Create or update a DigitalOcean Droplet
3. Configure the server with proper environment variables
4. Set up Docker and pull the latest image
5. Start the container with proper health checks

To deploy:
1. Create a `.env.production` file with your production settings
2. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

Alternatively, for manual deployment:
1. Build with platform specification:
   ```bash
   docker build --platform linux/amd64 -t registry.digitalocean.com/family-recipe-ai/family-recipe-ai:latest .
   ```
2. Push the image:
   ```bash
   docker push registry.digitalocean.com/family-recipe-ai/family-recipe-ai:latest
   ```
3. On the server, create the necessary directories and copy configuration:
   ```bash
   mkdir -p /root/family-recipe-ai
   scp .env.production docker-compose.yml root@YOUR_SERVER_IP:/root/family-recipe-ai/
   ssh root@YOUR_SERVER_IP "cd /root/family-recipe-ai && mv .env.production .env && docker compose up -d"
   ```

## 🔄 Integration with Family Site

The main Family Site application communicates with this service through HTTP requests. Make sure to:

1. Configure the correct API endpoint in the Family Site's configuration
2. Set the same API key in both services
3. Ensure CORS is properly configured for your production domains

In the main Flask application, create an `ai_client.py` module that handles communication with this service, including:

- Authentication with API key
- Error handling and retries
- Response parsing
- Caching to reduce API calls

## 🔍 Monitoring and Logging

- Logs are stored in the `logs/` directory
- Health checks are available at `/health`
- For production monitoring, consider:
  - Setting up Prometheus + Grafana
  - Using DigitalOcean's built-in monitoring
  - Implementing log aggregation (e.g., ELK stack)

## 🛡️ Security Considerations

- Keep your API keys secret and never commit them to version control
- Regularly rotate the API keys
- Use HTTPS in production
- Run the container with non-root user (already configured in Dockerfile)
- Implement rate limiting on the API endpoints
- Validate and sanitize all inputs

## 🤝 Contributing

1. Create a feature branch from `development`
2. Implement your changes
3. Add tests for new functionality
4. Submit a pull request

## 📄 License

This project is licensed under the terms of the MIT license.

