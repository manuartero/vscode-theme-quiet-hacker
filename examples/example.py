# Quiet Hacker - Python Preview
from dataclasses import dataclass, field
from typing import Optional, Generator
from pathlib import Path
import asyncio
import json

MAX_BUFFER = 1024
DEFAULT_ENCODING = "utf-8"


@dataclass
class Pipeline:
    """A simple data processing pipeline."""

    name: str
    steps: list[str] = field(default_factory=list)
    _running: bool = field(default=False, repr=False)

    @property
    def is_running(self) -> bool:
        return self._running

    def add_step(self, step: str) -> "Pipeline":
        self.steps.append(step)
        return self

    def __len__(self) -> int:
        return len(self.steps)


def read_chunks(path: Path, size: int = MAX_BUFFER) -> Generator[bytes, None, None]:
    """Read a file in fixed-size chunks."""
    with open(path, "rb") as f:
        while chunk := f.read(size):
            yield chunk


async def process(items: list[dict], workers: int = 4) -> list[Optional[str]]:
    results = []
    semaphore = asyncio.Semaphore(workers)

    async def _handle(item: dict) -> Optional[str]:
        async with semaphore:
            await asyncio.sleep(0.01)
            name = item.get("name")
            if name is None:
                return None
            return f"processed:{name}"

    tasks = [_handle(item) for item in items]
    results = await asyncio.gather(*tasks)
    return [r for r in results if r is not None]


# Dict comprehension + walrus operator
data = {"alpha": 1, "beta": 2, "gamma": None, "delta": 4}
filtered = {k: v for k, v in data.items() if (val := v) is not None and val > 1}

pipeline = Pipeline("etl").add_step("extract").add_step("transform").add_step("load")
print(f"Pipeline '{pipeline.name}' has {len(pipeline)} steps")

if __name__ == "__main__":
    items = [{"name": "a"}, {"name": None}, {"name": "b"}]
    result = asyncio.run(process(items))
    print(json.dumps(result, indent=2))
