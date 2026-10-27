# End-to-end tests

From stage 3: pytest scenarios against the running stack (platform + all services), e.g.
import a recipe → request a 3-day plan → accept it → get the shopping list. Each scenario also
asserts that the whole flow is **one trace** in Tempo spanning all services.
