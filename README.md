# Family Site AI Service

An AI-powered microservice built with FastAPI to enhance the Family Recipe Site with intelligent recipe suggestions and recipe text parsing.

## 📋 Overview

This service provides AI capabilities to the main Family Site application through a RESTful API. It features:

- Recipe suggestions based on available ingredients
- Intelligent parsing of unstructured recipe text
- Dietary preference-based recipe modifications
- Recipe scaling and ingredient substitution recommendations

## 🛠️ Technology Stack

- **FastAPI**: Modern, fast web framework for building APIs
- **OpenAI API**: For AI-powered recipe analysis and generation
- **Docker**: For containerization and deployment
- **Python 3.11+**: Core programming language

## 🚀 Getting Started

### Prerequisites

- Python 3.11 or higher
- Docker and Docker Compose
- OpenAI API key

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
   API_KEY=your_secret_api_key
   OPENAI_API_KEY=your_openai_api_key
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
| `API_KEY` | Secret API key for service authentication | Yes | - |
| `OPENAI_API_KEY` | OpenAI API key for AI functionality | Yes | - |
| `ENVIRONMENT` | Deployment environment (development/production) | No | development |
| `HOST` | Host to bind the server to | No | 0.0.0.0 |
| `PORT` | Port to bind the server to | No | 8000 |
| `ALLOWED_ORIGINS` | Comma-separated list of allowed CORS origins | No | http://localhost:5001,https://family-site.pythonanywhere.com |

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

