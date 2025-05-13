from locust import FastHttpUser, task

class WebsiteUser(FastHttpUser):
  # Define the host URL to access client.
  host = "http://127.0.0.1:8089"

  @task
  def index(self):
    # This task simulates a user accessing the root URL of the application.
    self.client.get("/")