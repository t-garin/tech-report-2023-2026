#import "@preview/hydra:0.6.2": anchor, hydra

#let headings-on-odd-page(it) = {
  show heading.where(level: 1): it => {
    {
      set page(footer: none, numbering: none, header: none)
      pagebreak(to: "odd")
    }
    it
  }
  it
}

#let template(front: none, main: none, doc) = [
  // font
  #set text(lang: "en", size: 12pt, font: "Atkinson Hyperlegible")
  // margins
  #let margins = (inside: 3.5cm, outside: 2.5cm, y: 2.5cm)
  #set page(margin: margins)
  // black line marking the extra inside margin (debug)
  #set page(background: context {
    let x = margins.inside - margins.outside
    let rule = line(length: page.height, angle: 90deg, stroke: black)
    if calc.even(here().page()) {
      place(top + right, dx: -x, rule)
    } else {
      place(top + left, dx: x, rule)
    }
  })
  // heading numbering
  #set heading(numbering: "I.A.1.")
  // line spacing and justified text
  #set par(justify: true, linebreaks: "optimized", leading: 1em, spacing: 2em)
  // titles and outline fonts
  #show heading: set text(font: "Fraunces")
  #show outline: set text(font: "Atkinson Hyperlegible")
  #show terms: it => {
    show strong: set text(font: "Fraunces")
    it
  }
  // figure captions: bold Fraunces label, light gray body, left-justified
  #show figure.caption: it => [
    #set text(fill: luma(67))
    #set par(justify: true)
    #strong(text(font: "Fraunces")[#it.supplement #it.counter.display()])#it.separator#it.body
  ]
  // table cell spacing
  #set table(inset: 10pt)
  // table double line for headers, https://forum.typst.app/t/how-to-get-double-line-rows-in-tables/4041/4
  #set table(row-gutter: (2.2pt, auto))
  // table headers in Fraunces bold
  #show table.cell.where(y: 0): it => {
    set text(font: "Fraunces")
    strong(it)
  }
  // table figures may span multiple pages
  #show figure.where(kind: table): set block(breakable: true)
  // code blocks
  #show raw: set text(font: "Atkinson Hyperlegible Mono")
  #show raw.where(block: true): block.with(
    fill: luma(240),
    inset: 12pt,
    radius: 4pt,
  )
  // custom first level headings with empty blank page inserted before, see: https://github.com/typst/typst/discussions/3122#discussioncomment-13936086
  #show heading.where(level: 1): it => [
    #set text(size: 30pt)
    #set par(justify: false, leading: 0.5em)
    #v(20%)
    #it
    #v(-1em)
    #line(length: 100%)
    #v(-0.25em)
  ]
  #show: headings-on-odd-page
  #show heading: it => [
    #it
    #v(0.5em)
  ]
  #show heading.where(level: 2): it => [
    #it
    #v(-1em)
    #line(length: 50%)
    #v(0.5em)
  ]
  // space between sections in outline
  #show outline.entry.where(
    level: 1,
  ): set block(above: 2em)
  // shorthand for point médian
  #show "..": "·"
  #show "||": set text(weight: "bold", fill: red)

  // front matter: cover page, preface, table of contents
  #front

  // since we dont put it in the header, need anchor, as per docs
  #set page(header: anchor())
  #show heading.where(level: 1): it => [#it #anchor()]
  #show heading.where(level: 2): it => [#it #anchor()]

  #set page(footer: context {
    if calc.even(here().page()) {
      align(left)[
        #set text(fill: luma(50%), size: 10pt)
        #counter(page).display("1")
        ---
        #emph(hydra(2))
      ]
    } else {
      align(right)[
        #set text(fill: luma(50%), size: 10pt)
        #emph(hydra(1))
        ---
        #counter(page).display("1")
      ]
    }
  })
  #counter(page).update(0)

  #main
  #doc
]

