from locust import HttpUser, task


class HelloWorldUser(HttpUser):
    @task
    def see_list(self):
        self.client.get("/")
        self.client.get("/api/leaderboard")
        self.client.get("/api/list")
        self.client.get("/api/vote?choice=:flushed:")

    @task
    def see_leaderboard(self):
        self.client.get("/")
        self.client.get("/api/list")
        self.client.get("/api/leaderboard")

    @task
    def vote(self):
        self.client.get("/")
        self.client.get("/api/list")
        self.client.get("/api/vote?choice=:flushed:")
        self.client.get("/api/vote?choice=:doughnut:")
