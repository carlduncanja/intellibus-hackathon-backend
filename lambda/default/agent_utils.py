from agents import Agent, Runner, ModelSettings

agent = Agent(
    name="Haiku agent",
    instructions="Always respond in haiku form",
    model_settings=ModelSettings(max_tokens=500)
)


def sample_ai_output():
    result = Runner.run_sync(agent, "Write a haiku about recursion in programming.")

    return result.final_output
