---
title: Presentation template
author: Ivan Trepakov
---

# Пример слайда с кириллицей

:::: columns
::: column

## Пример программы

```python
# Вычисление факториала числа n
def fact(n):
  if (n==1 or n==0):
    return 1
  else:
    return n * fact(n - 1)
```

:::
::: column

![](tikz/sample/Example.svg)

:::
::::

# Sample slide

::: columns
:::: {.column width=48%}

## First column

- You can use all Markdown features ~~and directly embed `\LaTeX`{=latex}~~

::::
:::: {.column width=48%}

## \centering Second column (centered)

- Markdown lists
- With ~~beautiful~~ ugly math: x^n + y^n = z^n
- And *easy* **Markdown** `styles`

::::
:::

# Sample slide

::: columns
:::: {.column width=48%}

## First column

- You can use all Markdown features ~~and directly embed `\LaTeX`{=latex}~~
- For images it is better to use vector graphics, e.g. in `.svg` or `.tikz`/`.gv` which is automatically converted into `.svg` via `Makefile` magic

::::
:::: {.column width=48%}

![](images/sample/Markdown-mark.svg)

::::
:::

# Sample slide

::: columns
:::: {.column width=48%}

## First column

- You can use all Markdown features ~~and directly embed `\LaTeX`{=latex}~~
- For images it is better to use vector graphics, e.g. in `.svg` or `.tikz`/`.gv` which is automatically converted into `.svg` via `Makefile` magic
- You can also use `.png` or `.jpg` but they usually look worse than `.svg`

::::
:::: {.column width=48%}

![](images/sample/Markdown-mark.svg)

![](images/sample/Markdown-mark.svg.png)

::::
:::

# Conclusion

## Summary

- Pandoc = Markdown + Ti*k*Z
- Please use this template and never open ~~Google Slides~~ PowerPoint ever again

# Thank you

