import logging
import os
import time
from datetime import datetime
from typing import Dict, List, Optional, Union

import uvicorn
from fastapi import Depends, FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import APIKeyHeader
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("ai-recipe-service")

# Configuration class
class Settings(BaseSettings):
    app_name: str = "Recipe AI Service"
    api_key: str = Field(..., alias="OPENROUTER_API_KEY")
    openrouter_url: str = Field("https://api.openrouter.com/v1", alias="OPENROUTER_URL")
    openrouter_model: str = Field(..., alias="OPENROUTER_MODEL")
    openrouter_site_url: str = Field(..., alias="OPENROUTER_SITE_URL")
    openrouter_app_name: str = Field(..., alias="OPENROUTER_APP_NAME")
    environment: str = "development"
    allowed_origins: List[str] = ["http://localhost:5001", "https://family-site.pythonanywhere.com"]
    
    class Config:
        env_file = ".env"

settings = Settings()

# API security
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)

async def get_api_key(api_key: str = Depends(api_key_header)):
    if api_key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API Key",
        )
    return api_key

# Pydantic models
class HealthResponse(BaseModel):
    status: str
    version: str
    timestamp: str

class RecipeIngredient(BaseModel):
    name: str
    quantity: Optional[float] = None
    unit: Optional[str] = None

class RecipeSuggestionRequest(BaseModel):
    ingredients: List[str] = Field(..., min_items=1, description="List of ingredient names")
    dietary_preferences: Optional[List[str]] = Field(None, description="List of dietary preferences like vegetarian, vegan, etc.")
    excluded_ingredients: Optional[List[str]] = Field(None, description="Ingredients to exclude from suggestions")

class RecipeSuggestion(BaseModel):
    title: str
    description: str
    ingredients: List[RecipeIngredient]
    instructions: List[str]
    cooking_time_minutes: Optional[int] = None
    preparation_time_minutes: Optional[int] = None
    servings: Optional[int] = None
    confidence_score: float = Field(..., ge=0.0, le=1.0)
    
class RecipeSuggestionResponse(BaseModel):
    suggestions: List[RecipeSuggestion]
    processing_time: float

class RecipeParsingRequest(BaseModel):
    recipe_text: str = Field(..., min_length=10)

class ParsedRecipe(BaseModel):
    title: str
    description: Optional[str] = None
    ingredients: List[RecipeIngredient]
    instructions: List[str]
    cooking_time_minutes: Optional[int] = None
    preparation_time_minutes: Optional[int] = None
    servings: Optional[int] = None
    
class RecipeParsingResponse(BaseModel):
    parsed_recipe: ParsedRecipe
    processing_time: float

# Create FastAPI app
app = FastAPI(
    title=settings.app_name,
    description="AI-powered recipe suggestions and parsing service",
    version="0.1.0",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request timing middleware
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    
    try:
        response = await call_next(request)
        process_time = time.time() - start_time
        response.headers["X-Process-Time"] = str(process_time)
        
        # Log request details
        logger.info(
            f"Request: {request.method} {request.url.path} - "
            f"Status: {response.status_code} - "
            f"Processing time: {process_time:.4f}s"
        )
        
        return response
    except Exception as e:
        logger.error(f"Request error: {str(e)}")
        process_time = time.time() - start_time
        
        # Return JSON error response
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"detail": "Internal server error occurred"},
            headers={"X-Process-Time": str(process_time)},
        )

# API endpoints
@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint for monitoring"""
    return {
        "status": "healthy",
        "version": app.version,
        "timestamp": datetime.now().isoformat(),
    }

@app.post(
    "/api/ai/recipe-suggestions", 
    response_model=RecipeSuggestionResponse,
    dependencies=[Depends(get_api_key)]
)
async def generate_recipe_suggestions(request: RecipeSuggestionRequest):
    """
    Generate recipe suggestions based on available ingredients
    and dietary preferences.
    """
    start_time = time.time()
    
    try:
        # This is a placeholder for the actual AI implementation
        # In a complete implementation, this would call an AI model/service
        logger.info(f"Processing recipe suggestions for {len(request.ingredients)} ingredients")
        
        # Mock data - in production this would use AI to generate suggestions
        suggestions = [
            RecipeSuggestion(
                title="Sample Recipe",
                description="This is a sample recipe suggestion.",
                ingredients=[
                    RecipeIngredient(name=ingredient, quantity=1.0, unit="cup")
                    for ingredient in request.ingredients[:3]
                ],
                instructions=[
                    "Mix all ingredients together.",
                    "Cook for 10 minutes.",
                    "Serve hot."
                ],
                cooking_time_minutes=10,
                preparation_time_minutes=5,
                servings=2,
                confidence_score=0.85
            )
        ]
        
        processing_time = time.time() - start_time
        return {
            "suggestions": suggestions,
            "processing_time": processing_time
        }
    except Exception as e:
        logger.error(f"Error generating recipe suggestions: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate recipe suggestions: {str(e)}"
        )

@app.post(
    "/api/ai/recipe-parsing", 
    response_model=RecipeParsingResponse,
    dependencies=[Depends(get_api_key)]
)
async def parse_recipe(request: RecipeParsingRequest):
    """
    Parse an unstructured recipe text into structured recipe data.
    """
    start_time = time.time()
    
    try:
        # This is a placeholder for the actual AI implementation
        # In a complete implementation, this would call an AI model/service
        logger.info(f"Parsing recipe text of length {len(request.recipe_text)}")
        
        # Mock data - in production this would use AI to parse the recipe
        parsed_recipe = ParsedRecipe(
            title="Parsed Recipe Title",
            description="This is a parsed recipe description.",
            ingredients=[
                RecipeIngredient(name="ingredient 1", quantity=1.0, unit="cup"),
                RecipeIngredient(name="ingredient 2", quantity=2.0, unit="tablespoon"),
            ],
            instructions=[
                "Step 1: Prepare ingredients.",
                "Step 2: Mix together.",
                "Step 3: Cook and serve."
            ],
            cooking_time_minutes=15,
            preparation_time_minutes=10,
            servings=4
        )
        
        processing_time = time.time() - start_time
        return {
            "parsed_recipe": parsed_recipe,
            "processing_time": processing_time
        }
    except Exception as e:
        logger.error(f"Error parsing recipe: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to parse recipe: {str(e)}"
        )

# Global exception handler for unhandled exceptions
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An unexpected error occurred"},
    )

# Run the application when executed directly
if __name__ == "__main__":
    # Use environment variables or defaults
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    
    # Start the uvicorn server
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=settings.environment == "development",
        log_level="info",
    )
