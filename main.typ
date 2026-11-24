#import "style.typ": template
#show: template.with(
  front: [
    #include "typs/cover-page.typ"
    #include "typs/preface.typ"
    #outline()
  ],
  main: [
    #include "typs/context.typ"
    #include "typs/seiche.typ"
    #include "typs/fsfs.typ"
    #include "typs/conclusion.typ"

    // reset numbering for appendices
    #set heading(numbering: "A.i.")
    #counter(heading).update(0)

    #include "typs/appendix.typ"
    #include "typs/appendix-data-sources.typ"
    #include "typs/appendix-seiche-docs-config.typ"
    #include "typs/appendix-seiche-docs-nomenclature.typ"
    #include "typs/appendix-seiche-docs-flow.typ"
    #include "typs/appendix-seiche-docs-api-src.typ"
    #include "typs/appendix-seiche-docs-api-tools.typ"

    #outline(
      title: [Figures Index],
      target: figure.where(kind: image),
    )

    #outline(
      title: [Tables Index],
      target: figure.where(kind: table),
    )

    #outline(
      title: [Listings Index],
      target: figure.where(kind: raw),
    )

    #bibliography("bib.bib")
  ],
)
