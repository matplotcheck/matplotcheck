# MatPlotCheck AI Development Guide

## Project Overview

MatPlotCheck is a testing framework for validating Matplotlib plots, primarily used for autograding in data science education. The package provides assertion-based testing for plot elements (data, titles, axes, legends) across various plot types including basic plots, spatial vector/raster visualizations, time series, and Folium maps.

## Architecture & Core Patterns

### Two-Layer Testing Architecture

The codebase uses a dual-interface pattern:

1. **Tester Classes** (Low-level): Direct assertion methods

   - `PlotTester` ([base.py](matplotcheck/base.py)): Base class with core plotting assertions
   - `VectorTester` ([vector.py](matplotcheck/vector.py)): Spatial vector plot testing
   - `RasterTester` ([raster.py](matplotcheck/raster.py)): Raster/image plot testing
   - `TimeSeriesTester` ([timeseries.py](matplotcheck/timeseries.py)): Time series specific checks
   - `FoliumTester` ([folium.py](matplotcheck/folium.py)): Folium map testing

2. **Suite Classes** (High-level): `unittest.TestCase` wrappers grouping related assertions
   - `PlotBasicSuite`, `PlotHistogramSuite`, `PlotTimeSeriesSuite`, etc. ([cases.py](matplotcheck/cases.py))
   - Dynamically generate test classes with `unittest.skipIf` decorators
   - Use pattern: `unittest.TextTestRunner().run(suite)` for execution

**Usage Pattern**: Direct assertions for fine-grained control, Suites for comprehensive validation.

### Inheritance Hierarchy

```
PlotTester (base.py)
├── VectorTester (vector.py)
│   └── RasterTester (raster.py)
└── TimeSeriesTester (timeseries.py)
```

### String Matching Convention

All string assertions use **case-insensitive, whitespace-stripped** matching via `assert_string_contains()`:

- Accepts nested lists for OR logic: `["x", ["label", "axis"]]` means "x" AND ("label" OR "axis")
- Parameters like `title_contains`, `xlabel_contains` accept `None` (skip test) or `[]` (test existence only)

## Development Workflow

### Environment Setup

```bash
uv sync --dev
source .venv/bin/activate
```

### Testing

```bash
pytest                    # Run all tests
pytest -m requires_geopandas  # Run tests requiring optional deps
```

Use pytest markers in [conftest.py](matplotcheck/tests/conftest.py):

- `@pytest.mark.requires_geopandas`
- `@pytest.mark.requires_scipy`
- `@pytest.mark.requires_folium`

### Fixtures Pattern

Test fixtures in [conftest.py](matplotcheck/tests/conftest.py) create plot objects (`pt_line_plt`, `pt_scatter_plt`, etc.). Always call `plt.close()` in tests to prevent memory leaks.

### Documentation

```bash
make build-docs          # Full build with API docs
make preview-docs        # Live-reload dev server
```

## Type Checking & Code Quality

- **MyPy**: Enabled for `base.py` with strict typing (`disallow_untyped_defs = true`). Other modules are gradually typed.
- **Black**: Line length 79 (PEP 8 strict)
- **Ruff**: Modern linter (replaces flake8/isort)

Type hints use:

- `matplotlib.axes.Axes` not `plt.Axes`
- `Optional[Union[...]]` for flexible parameters
- `NDArray` from `numpy.typing` for arrays

## Optional Dependencies Pattern

Critical pattern for handling optional imports (see [base.py](matplotcheck/base.py#L24-L42)):

```python
try:
    import geopandas as gpd
    HAS_GEOPANDAS = True
except ImportError:
    HAS_GEOPANDAS = False
    if TYPE_CHECKING:
        import geopandas as gpd
```

Always guard optional features with `HAS_<LIBRARY>` checks and provide clear error messages.

## Key Implementation Details

### Axes Introspection

- Access plot data via `ax.lines`, `ax.collections`, `ax.patches`, `ax.images`
- Line plots: Check `get_linestyle()`, `get_linewidth()` (see `_is_line()`)
- Scatter: Check `PathCollection` in `ax.collections`
- Raster: Access via `ax.images[0].get_array()`

### Test Suite Generation

Suites in [cases.py](matplotcheck/cases.py) dynamically create `unittest.TestCase` classes within `__init__()`, allowing parameterized test configuration while maintaining unittest compatibility.

### Vector Testing Pattern

`get_points_by_attributes()` and `get_lines_by_attributes()` return sorted lists grouped by visual attributes (color, size, style) for comparing expected vs actual spatial data.

## Common Pitfalls

1. **Renderer Requirement**: Some methods need `draw_renderer()` for accurate text bounding boxes
2. **Collection Types**: Check `isinstance(coll, matplotlib.collections.PathCollection)` to distinguish scatter from other collections
3. **Empty Lists vs None**: `[]` tests existence, `None` skips test entirely
4. **Coordinate Systems**: Spatial tests use offsets (data coords) + styles (marker coords)

## Package Distribution

- Published as `matplotcheck2` on PyPI (fork of original `matplotcheck`)
- Core deps: `matplotlib>=3.10.1`, `numpy>=2.0.0`, `pandas>=2.0.0`
- Optional extras: `[spatial]`, `[timeseries]`, `[folium]`, `[all]`, `[docs]`
