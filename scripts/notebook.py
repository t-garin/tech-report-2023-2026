import marimo

__generated_with = "0.24.0"
app = marimo.App(width="medium")


@app.cell(hide_code=True)
def _():
    import marimo as mo
    import numpy as np
    import pandas as pd
    import geopandas as gpd
    import xarray as xr
    import contextily as cx
    import hashlib
    import matplotlib.pyplot as plt
    import matplotlib.patches as mpatches
    from matplotlib.patches import ConnectionPatch, Rectangle
    import matplotlib.dates as mdates
    import matplotlib.colors as mcolors
    from matplotlib.colors import LightSource, LogNorm
    import seaborn as sns
    import os
    import shapely
    from pathlib import Path
    from seiche.format_slf import Slf
    from seiche.defended import defended
    from seiche.utils_da import reproj_clip
    from seiche.utils_enum import DefendedMethod
    from seiche.utils_plot import Colors
    import rioxarray as rxr
    import cartopy.crs as ccrs
    import cartopy.feature as cfeature
    from rasterio.transform import xy

    return (
        Colors,
        ConnectionPatch,
        DefendedMethod,
        LightSource,
        LogNorm,
        Path,
        Rectangle,
        Slf,
        ccrs,
        cfeature,
        cx,
        defended,
        gpd,
        hashlib,
        mcolors,
        mdates,
        mpatches,
        np,
        os,
        pd,
        plt,
        reproj_clip,
        rxr,
        shapely,
        sns,
        xy,
        xr,
    )


@app.cell(hide_code=True)
def _(Path, gpd, os, plt, shapely):
    plt.rcParams.update({
        "text.usetex": True,
        "font.family": "serif"
    })

    A4H = 29.7 / 2.54  # A4 height in inches
    A4W = 21.0 / 2.54  # A4 width in inches

    FLOOD_TYPE_COLORS = {
        "Runoff": plt.get_cmap("tab10")(0),
        "Overflowing": plt.get_cmap("tab10")(1),
        "Overflowing and runoff": plt.get_cmap("tab10")(2),
        "Rising water table": plt.get_cmap("tab10")(3),
        "Runoff and rising water table": plt.get_cmap("tab10")(4),
        "Unknown": plt.get_cmap("tab10")(5),
        "Source": plt.get_cmap("tab10")(6),
    }


    os.environ.setdefault(
        "SEICHE_OPENTELEMAC_PATH",
        str(Path.home() / ".local/bin/opentelemac_python3_20240430"),
    )

    CENTER = (467819, 6383697)
    HALF = 1000  # 2x2 km bbox
    BBOX = shapely.box(
        CENTER[0] - HALF, CENTER[1] - HALF, CENTER[0] + HALF, CENTER[1] + HALF
    )
    BBOX_GDF = gpd.GeoDataFrame(geometry=[BBOX], crs="EPSG:2154")
    return A4H, A4W, BBOX, BBOX_GDF, FLOOD_TYPE_COLORS


@app.function(hide_code=True)
def save_figure(fig, path):
    fig.savefig(path, dpi=300, bbox_inches="tight")
    print(f"Saved {path}")
    return None


@app.cell(hide_code=True)
def _(gpd, hashlib, np, pd, sample, xr):
    class _Rex:
        def __init__(
            self, datadir: str = "/archive2/globc/seiche/SmageAa/rex_smageaa"
        ) -> None:
            self.files = self._read_files(datadir=datadir)
            rex = self._format_rex(self.files)
            self.bati = rex["BATI"]
            self.zone = rex["ZONE"]
            self.voie = rex["VOIE"]
            self.axes = rex["AXES"]
            return None

        @staticmethod
        def _read_files(datadir: str) -> dict[gpd.GeoDataFrame]:
            paths = {
                "AXES": f"{datadir}/axes_ruissellement.shp",
                "BATI": f"{datadir}/bati_inondation.shp",
                "ZONE": f"{datadir}/zones_inondation.shp",
                "VOIE": f"{datadir}/voirie_inondation.shp",
            }
            hashes = {
                "AXES": "ce646dbaf0857415675ba3e4b4d17a7ea672309a239399e7af3f662419e48172",
                "BATI": "2f67e8af5f2fa8e57ff82fe9a9fb10e389935a570ec544b550315f86941e4bb8",
                "ZONE": "8a9d123cea756574b596799745d93138e174b7828de657b01f33bbf8404b6b08",
                "VOIE": "01c35ed8720cea681acdc211db4b2e16cf14d6191e54c8f95157c09af1726467",
            }
            for key, path in paths.items():
                with open(path, "rb") as f:
                    computed_sha256 = hashlib.file_digest(f, "sha256").hexdigest()
                assert computed_sha256 == hashes[key], (
                    f"Hash mismatch for {key}: {computed_sha256} != {hashes[key]}"
                )
            return {k: gpd.read_file(v) for k, v in paths.items()}

        @staticmethod
        def _format_rex(files: dict[gpd.GeoDataFrame]) -> dict[gpd.GeoDataFrame]:
            # ==========================================================================
            def split_dates(df):
                new_rows = []
                for _, row in df.iterrows():
                    for i in range(1, 5):  # 1, 2, 3, 4
                        date = row[f"DATE{i}"]
                        event = row[f"EVENEMENT{i}"]
                        if pd.notna(date) and pd.notna(event):
                            new_row = row.drop(
                                labels=[f"DATE{j}" for j in range(1, 5)]
                                + [f"EVENEMENT{j}" for j in range(1, 5)]
                            )
                            new_row["DATE"] = date
                            new_row["EVENEMENT"] = event
                            new_rows.append(new_row)
                return gpd.GeoDataFrame(
                    new_rows, columns=new_row.index
                ).reset_index(drop=True)

            # ==========================================================================
            def date_parse(
                date_str: str,
            ) -> tuple[pd.Timestamp, pd.Timestamp, pd.Timestamp]:
                """
                For each date, returns MIN, MEAN, MAX.
                Format is DD1-DD2/MM/YYYY (a shorthand for DD1/MM/YYYY to DD2/MM/YYYY)
                or DD/MM/YYYY.
                """
                days, month, year = date_str.split("/")
                d0, _, d1 = days.partition("-") if "-" in days else (days, "", days)
                lo = pd.Timestamp(year=int(year), month=int(month), day=int(d0))
                hi = pd.Timestamp(
                    year=int(year), month=int(month), day=int(d1),
                    hour=23, minute=59, second=59,
                )
                return lo, lo + (hi - lo) / 2, hi

            # ==========================================================================
            def apply_date_parse(gdf: gpd.GeoDataFrame) -> gpd.GeoDataFrame:
                g = gdf.copy()
                for idx, row in gdf.iterrows():
                    date_min, date_mean, date_max = date_parse(row["DATE"])
                    g.loc[idx, "DATE_MIN"] = date_min
                    g.loc[idx, "DATE_MEAN"] = date_mean
                    g.loc[idx, "DATE_MAX"] = date_max
                return g

            # ==========================================================================
            traduction = {
                "Débordement cours d'eau": "Overflowing",
                "Inconnu": "Unknown",
                "Remontée de nappe": "Rising water table",
                "Ruissellement": "Runoff",
                "Ruissellement et débordement": "Overflowing and runoff",
                "Ruissellement et remontée de nappe": "Runoff and rising water table",
                "Débordement cours d'eau et ruissellement": "Overflowing and runoff",
                "Ruissellement et débordement cours d'eau": "Overflowing and runoff",
            }

            # ==========================================================================
            @np.vectorize(otypes=[bool])
            def is_not_none(x):
                return x is not None

            # ==========================================================================
            for k, v in files.items():
                if k == "AXES":
                    continue
                v = split_dates(v)
                # data cleaning
                match k:
                    case "VOIE":
                        # swap the values of DATE and EVENEMENT for the row with index 827 in VOIE
                        v.loc[827, ["DATE", "EVENEMENT"]] = v.loc[
                            827, ["EVENEMENT", "DATE"]
                        ].values
                        # replace 06/11/2032 with 06/11/2023
                        v.loc[v["DATE"] == "06/11/2032", "DATE"] = "06/11/2023"
                    case "ZONE":
                        # replace 02/01/2023 with 02/01/2024
                        v.loc[v["DATE"] == "02/01/2023", "DATE"] = "02/01/2024"
                    case _:
                        ...
                #
                v = apply_date_parse(v)
                v["EVENEMENT"] = v["EVENEMENT"].replace(traduction)
                v = v[v["geometry"].apply(is_not_none)].copy()
                v["area"] = v.geometry.area
                files[k] = v.set_crs(epsg=2154)
            return files

        def concat_seiche_hazard(self, hzd: xr.DataArray, prefix: str) -> None:
            self.bati.loc[:, f"{prefix}_H"] = sample(
                hzd.isel(band=0), self.bati["geometry"]
            )
            self.bati.loc[:, f"{prefix}_V"] = sample(
                hzd.isel(band=1), self.bati["geometry"]
            )
            self.bati.loc[:, f"{prefix}_T"] = sample(
                hzd.isel(band=2), self.bati["geometry"]
            )
            # Need to add zone and axes and voie
            return None

        def concat_seiche_raster(self, raster: xr.DataArray, colname: str) -> None:
            self.bati.loc[:, f"{colname}"] = sample(
                raster.isel(band=0), self.bati["geometry"]
            )
            # Need to add zone and axes and voie
            return None

    Rex = _Rex()
    return (Rex,)


@app.cell(hide_code=True)
def _(A4W, BBOX, BBOX_GDF, cx, np, plt, reproj_clip):
    # Persist contextily's tile cache across sessions (default is a temp dir
    # that is deleted afterwards), so basemaps are fetched only once.
    cx.set_cache_dir("/data/scratch/globc/garin/.cache/contextily")

    def bbox_label(bbox=BBOX):
        xmin, ymin, xmax, ymax = bbox.bounds
        return (
            f"2x2km box centered on Couthures-sur-Garonne\n"
            f"[{xmin:.0f}, {ymin:.0f}, {xmax:.0f}, {ymax:.0f}] (EPSG:2154)"
        )

    def bbox_figure(figsize=(A4W/2, A4W/2)):
        fig, ax = plt.subplots(figsize=figsize)
        ax.set_xlim(BBOX.bounds[0], BBOX.bounds[2])
        ax.set_ylim(BBOX.bounds[1], BBOX.bounds[3])
        ax.set_aspect("equal")
        ax.set_axis_off()
        ax.set_title(bbox_label(), fontsize=10, y=1)
        return fig, ax

    def bottom_colorbar(fig, ax, mappable, label=""):
        cb = fig.colorbar(
            mappable, ax=ax, location="bottom", fraction=0.047, pad=0.01
        )
        cb.set_label(label, fontsize=9)
        return cb

    def add_basemap(ax, crs="EPSG:2154", alpha=0.7):
        cx.add_basemap(
            ax,
            source=cx.providers.OpenStreetMap.Mapnik,
            crs=crs,
            alpha=alpha,
            attribution="",  # OSM attribution moved to the figure captions
            headers={"User-Agent": "seiche-technical-report/1.0 (research; contact: garin@cerfacs.fr)"},
        )

    def imshow_bbox(ax, da, **kw):
        xmin, ymin, xmax, ymax = da.rio.bounds()
        return ax.imshow(
            da.squeeze(), extent=(xmin, xmax, ymin, ymax), origin="upper", **kw
        )

    def bbox_figure_raster_plot(
        da, path, *,
        label="", cmap="viridis", norm=None, vmin=None, vmax=None,
        basemap=False, outline=False, legend=None,
    ):
        da = reproj_clip(da, 2154, BBOX_GDF)
        fig, ax = bbox_figure()
        if basemap:
            add_basemap(ax)
        mappable = imshow_bbox(ax, da, cmap=cmap, norm=norm, vmin=vmin, vmax=vmax)
        if outline:
            mask = np.isfinite(da.squeeze().values).astype(float)
            ny, nx = mask.shape
            xmin, ymin, xmax, ymax = da.rio.bounds()
            ax.contour(np.linspace(xmin, xmax, nx), np.linspace(ymax, ymin, ny),
                       mask, levels=[0.5], colors="black", linewidths=0.5)
        if legend:
            ax.legend(**legend)
        if label:
            bottom_colorbar(fig, ax, mappable, label=label)
        save_figure(fig, path)
        return fig, ax

    return (
        add_basemap,
        bbox_figure,
        bbox_figure_raster_plot,
        bottom_colorbar,
        imshow_bbox,
    )


@app.cell(hide_code=True)
def _(A4H, A4W, FLOOD_TYPE_COLORS, Rex, cx, mpatches, plt):
    def rex_flood_types_map():

        bati_df = Rex.bati[["EVENEMENT", "geometry"]].copy()
        voie_df = Rex.voie[["EVENEMENT", "geometry"]].copy()
        voie_df.geometry = voie_df.geometry.buffer(50)
        zone_df = Rex.zone[["EVENEMENT", "geometry"]].copy()

        fig, ax = plt.subplots(figsize=(A4W, A4H))

        zone_df.plot(
            ax=ax,
            color=zone_df["EVENEMENT"].map(FLOOD_TYPE_COLORS),
            edgecolor="k",
            linewidth=0.5,
        )

        voie_df.plot(
            ax=ax,
            color=voie_df["EVENEMENT"].map(FLOOD_TYPE_COLORS),
            edgecolor="k",
            linewidth=0.5,
        )

        bati_df.plot(
            ax=ax,
            color=bati_df["EVENEMENT"].map(FLOOD_TYPE_COLORS),
            markersize=40,
            marker="*",
            edgecolor="k",
            linewidth=0.25,
        )

        legend_handles = [
            mpatches.Patch(color=FLOOD_TYPE_COLORS[cat], label=cat)
            for cat in sorted(FLOOD_TYPE_COLORS.keys())
        ]

        ax.legend(
            handles=legend_handles,
            loc="lower right",
            fontsize=12,
            frameon=True,
        )

        cx.add_basemap(
            ax,
            source=cx.providers.GeoportailFrance.plan,
            zoom=12,
            attribution="Basemap: IGN",
            crs=Rex.zone.crs,
            alpha=0.5,
        )

        ax.set_title("")
        ax.set_aspect("equal")
        ax.set_axis_off()

        path = "../imgs/rex_flood_types_map.png"
        save_figure(fig, path)
        return ax

    rex_flood_types_map()
    return


@app.cell(hide_code=True)
def _(A4H, A4W, FLOOD_TYPE_COLORS, Rex, mdates, plt, sns):
    def rex_flood_types_timeline():

        with sns.axes_style("darkgrid"):

            fig, axes = plt.subplots(
                3, 1, figsize=(A4W, A4H * (2 / 3)), sharex=True
            )

            for df, axidx, agg, title, ylabel in zip(
                [Rex.zone, Rex.voie, Rex.bati],
                [0, 1, 2],
                ["sum", "sum", "count"],
                ["Flooded Areas", "Flooded Roads", "Flooded Buildings"],
                ["Area ($m^2$)", "Area ($m^2$)", "Num. of buildings"],
            ):
                df = (
                    df[["DATE_MEAN", "area", "EVENEMENT"]]
                    .copy()
                    .groupby(["DATE_MEAN", "EVENEMENT"])
                )
                df = df.sum() if agg == "sum" else df.count()
                df = df.reset_index().copy()
                df = df.pivot(
                    index="DATE_MEAN", columns="EVENEMENT", values="area"
                )
                df = df.resample("1D").sum()
                df.plot(
                    kind="bar",
                    stacked=True,
                    width=1,
                    ax=axes[axidx],
                    color=FLOOD_TYPE_COLORS,
                    legend=False,
                )
                axes[axidx].set_ylabel(ylabel)
                axes[axidx].set_xlabel("")
                axes[axidx].set_title(
                    title, loc="right", pad=3 if axidx == 2 else 0, fontsize=12
                )

            axes[2].set_ylim(0, 3000)

            # xticks
            axes[2].xaxis.set_major_locator(mdates.DayLocator(interval=7))
            axes[2].xaxis.set_major_formatter(mdates.DateFormatter("%b. %d"))
            plt.setp(axes[2].get_xticklabels(), rotation=0, ha="center")

            # legend
            fig.legend(
                *axes[2].get_legend_handles_labels(),
                loc="upper center",
                ncol=3,
                bbox_to_anchor=(0.5, 0.98),
                fontsize="medium",
                frameon=True,
            )

            path = "../imgs/rex_flood_types_timeline.png"
            save_figure(fig, path)
            return fig

    rex_flood_types_timeline()
    return


@app.cell(hide_code=True)
def _(Path, Slf, bbox_figure, bottom_colorbar):
    def plot_slf_mesh_bbox():
        slf = Slf(
            epsg=2154,
            depth_varname="HAUTEUR D'EAU",
            x_speed_varname="VITESSE U",
            y_speed_varname="VITESSE V",
            freesurf_varname="SURFACE LIBRE",
            file_name=str(
                Path.home() / "seiche/tests/marmande_light/hf_k17_2019_light.slf"
            ),
        )
        depth = slf.get_timeseries_on_nodes(
            "HAUTEUR D'EAU", range(slf.npoin2)
        ).max(axis=1)
        fig, ax = bbox_figure()
        mappable = ax.tripcolor(slf.tri, depth, shading="gouraud", cmap="Blues")
        ax.triplot(slf.tri, lw=0.1, color="k", alpha=0.3)
        bottom_colorbar(fig, ax, mappable, label="Max depth (m)")
        save_figure(fig, "../imgs/slf_mesh_bbox.png")
        return ax

    plot_slf_mesh_bbox()
    return


@app.cell(hide_code=True)
def _(BBOX_GDF, np, reproj_clip, rxr):
    # SEICHE hazard (H, V, T) from the hf_k17 2019 Telemac2D model, on the 2x2 km bbox.
    hzd = rxr.open_rasterio(
        "/archive2/globc/seiche/marmande_2019_out/hzd_hf_2019_k17_marmande.tif"
    )
    h = reproj_clip(hzd.isel(band=0), 2154, BBOX_GDF)
    v = reproj_clip(hzd.isel(band=1), 2154, BBOX_GDF)
    t = reproj_clip(hzd.isel(band=2), 2154, BBOX_GDF) / 86400  # s -> days
    vmaxs = {
        "h": float(np.nanpercentile(h.values, 99.5)),
        "v": float(np.nanpercentile(v.values, 99.5)),
        "t": float(np.nanpercentile(t.values, 99.5)),
    }
    return h, t, v, vmaxs


@app.cell(hide_code=True)
def _(bbox_figure_raster_plot, h, vmaxs):
    _, _ax = bbox_figure_raster_plot(
        h, "../imgs/hzd_h_bbox.png",
        label="Max depth $H$ (m)", cmap="Reds", vmin=0, vmax=vmaxs["h"],
    )
    _ax
    return


@app.cell(hide_code=True)
def _(bbox_figure_raster_plot, v, vmaxs):
    _, _ax = bbox_figure_raster_plot(
        v, "../imgs/hzd_v_bbox.png",
        label="Max velocity $V$ (m/s)", cmap="Greens", vmin=0, vmax=vmaxs["v"],
    )
    _ax
    return


@app.cell(hide_code=True)
def _(bbox_figure_raster_plot, t, vmaxs):
    _, _ax = bbox_figure_raster_plot(
        t, "../imgs/hzd_t_bbox.png",
        label="Flood duration $T$ (days)", cmap="Blues", vmin=0, vmax=vmaxs["t"],
    )
    _ax
    return


@app.cell(hide_code=True)
def _(bbox_figure, h, np, t, v, vmaxs):
    rgb = np.ma.masked_invalid(np.stack([
        np.clip(h.values / vmaxs["h"], 0, 1),
        np.clip(v.values / vmaxs["v"], 0, 1),
        np.clip(t.values / vmaxs["t"], 0, 1),
    ], axis=-1))
    fig_rgb, ax_rgb = bbox_figure()
    xmin, ymin, xmax, ymax = h.rio.bounds()
    ax_rgb.imshow(rgb, extent=(xmin, xmax, ymin, ymax), origin="upper")
    ax_rgb.set_title(
        ax_rgb.get_title()
        + "\n$H$: red, $V$: green, $T$: blue — each band normalized to [0, 1]",
        fontsize=8,
    )
    save_figure(fig_rgb, "../imgs/hzd_hvt_rgb_bbox.png")
    ax_rgb
    return


@app.cell(hide_code=True)
def _(bbox_figure_raster_plot, rxr):
    rge_alti = rxr.open_rasterio("/archive2/globc/seiche/marmande_2019_inp/rge_alti.tif")
    _, _ax = bbox_figure_raster_plot(rge_alti, "../imgs/dem_rge_alti_bbox.png", label="Elevation (m)", cmap="terrain", vmin=10, vmax=35)
    _ax
    return


@app.cell(hide_code=True)
def _(bbox_figure_raster_plot, rxr):
    glo30 = rxr.open_rasterio("/archive2/globc/seiche/marmande_2019_inp/demglo30_2011-part1.tif")
    _, _ax = bbox_figure_raster_plot(glo30, "../imgs/dem_copernicus30_bbox.png", label="Elevation (m)", cmap="terrain", vmin=10, vmax=35)
    _ax
    return


@app.cell(hide_code=True)
def _(BBOX_GDF, reproj_clip, rxr):
    rge_alti2 = rxr.open_rasterio("/archive2/globc/seiche/marmande_2019_inp/rge_alti.tif")
    glo30_2 = rxr.open_rasterio("/archive2/globc/seiche/marmande_2019_inp/demglo30_2011-part1.tif")
    rge_30 = reproj_clip(rge_alti2, 2154, BBOX_GDF).rio.reproject_match(glo30_2)
    diff = glo30_2 - rge_30  # GLO-30 - RGE-Alti (30 m reproj), on the 30 m grid
    return diff


@app.cell(hide_code=True)
def _(bbox_figure_raster_plot, diff):
    _, _ax = bbox_figure_raster_plot(
        diff, "../imgs/dem_diff_bbox.png",
        label="GLO-30 (30 m) − RGE-Alti (30 m reproj) (m)", cmap="RdBu", vmin=-5, vmax=5,
    )
    _ax
    return


@app.cell(hide_code=True)
def _(A4W, diff, np, plt):
    vals = diff.values[np.isfinite(diff.values)]
    fig_hist, ax_hist = plt.subplots(figsize=(A4W/2, A4W/2))
    ax_hist.hist(vals, bins=100, color="#888", edgecolor="none")
    ax_hist.axvline(0.0, color="k", ls="--", lw=1, label="0 m (no bias)")
    ax_hist.axvline(np.median(vals), color="#d62728", lw=1,
                    label=f"median = {np.median(vals):+.2f} m")
    ax_hist.set_xlim(np.percentile(vals, [0.5, 99.5]))
    ax_hist.set_xlabel("GLO-30 (30 m) − RGE-Alti (30 m reproj) (m)")
    ax_hist.set_ylabel("Pixel count (30 m)")
    ax_hist.legend(fontsize=8)
    save_figure(fig_hist, "../imgs/dem_diff_hist.png")
    ax_hist
    return


@app.cell(hide_code=True)
def _(BBOX_GDF, Colors, bbox_figure_raster_plot, mcolors, mpatches, np, reproj_clip, rxr):
    OSO_NAMES = {
        1: "Urbain dense", 2: "Urbain diffus", 3: "Zone industrielle et commerciale",
        4: "Routes", 5: "Oléagineux d'hiver", 6: "Céréales à paille",
        7: "Protéagineux de printemps", 8: "Soja", 9: "Tournesol", 10: "Mais",
        11: "Riz", 12: "Tubercules/racines", 13: "Prairies", 14: "Vergers",
        15: "Vignes", 16: "Forêts de feuillus", 17: "Forêts de conifères",
        18: "Pelouses", 19: "Landes", 20: "Surfaces minérales",
        21: "Plages et dunes", 22: "Glaciers et neiges éternelles", 23: "Eau",
    }
    ESAWC_NAMES = {
        10: "Tree cover", 20: "Shrubland", 30: "Grassland", 40: "Cropland",
        50: "Built-up", 60: "Bare / sparse vegetation", 70: "Snow and ice",
        80: "Permanent water bodies", 90: "Herbaceous wetland", 95: "Mangroves",
        100: "Moss and lichen",
    }

    def categorical_bbox_plot(da, path, cmap, bounds, names):
        da = reproj_clip(da, 2154, BBOX_GDF).where(lambda d: d > 0)
        norm = mcolors.BoundaryNorm(bounds, cmap.N)
        present = sorted(
            v for v in names if v in np.unique(da.values[np.isfinite(da.values)])
        )
        handles = [mpatches.Patch(color=cmap(norm(v)), label=names[v]) for v in present]
        return bbox_figure_raster_plot(
            da, path, cmap=cmap, norm=norm,
            legend=dict(handles=handles, loc="upper center",
                        bbox_to_anchor=(0.5, -0.05), ncol=2, fontsize=6, frameon=True),
        )

    return ESAWC_NAMES, OSO_NAMES, categorical_bbox_plot


@app.cell(hide_code=True)
def _(Colors, OSO_NAMES, categorical_bbox_plot, rxr):
    _, _ax = categorical_bbox_plot(
        rxr.open_rasterio("/archive2/globc/seiche/marmande_2019_inp/oso_2019.tif"),
        "../imgs/lcv_oso_bbox.png", Colors.oso23_list,
        [i + 0.5 for i in range(24)], OSO_NAMES,
    )
    _ax
    return


@app.cell(hide_code=True)
def _(Colors, ESAWC_NAMES, categorical_bbox_plot, rxr):
    _, _ax = categorical_bbox_plot(
        rxr.open_rasterio("/archive2/globc/seiche/marmande_2019_inp/esawc_2020.tif"),
        "../imgs/lcv_esawc_bbox.png", Colors.esawc_list,
        [5, 15, 25, 35, 45, 55, 65, 75, 85, 92.5, 97.5, 105], ESAWC_NAMES,
    )
    _ax
    return


@app.cell(hide_code=True)
def _(BBOX, add_basemap, bbox_figure, gpd, mpatches, pd):
    def plot_assets():
        bbox = BBOX.bounds
        rpg = gpd.read_file("/archive2/globc/seiche/marmande_2019_inp/rpg_2020.shp", bbox=bbox)
        bdtopo = gpd.read_file("/archive2/globc/seiche/marmande_2019_inp/bdtopo_bati_2019-12.shp", bbox=bbox)
        sirene = pd.read_csv(
            "/archive2/globc/seiche/marmande_2019_inp/sirene_2019-12.csv",
            usecols=["longitude", "latitude"],
        ).dropna()
        sirene = gpd.GeoDataFrame(
            sirene,
            geometry=gpd.points_from_xy(sirene.longitude, sirene.latitude),
            crs="EPSG:4326",
        ).to_crs("EPSG:2154").clip(bbox)

        fig, ax = bbox_figure()
        add_basemap(ax)
        rpg.plot(ax=ax, color="#2E8B57", alpha=0.6, edgecolor="none")
        bdtopo.plot(ax=ax, color="#C31400", edgecolor="k", linewidth=0.2)
        sirene.plot(ax=ax, color="blue", markersize=4)
        handles = [
            mpatches.Patch(facecolor="#2E8B57", label="RPG parcels"),
            mpatches.Patch(facecolor="#C31400", label="BdTopo buildings"),
            mpatches.Patch(facecolor="blue", label="Sirène establishments"),
        ]
        ax.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.5, -0.05),
                  ncol=2, fontsize=8, frameon=True)
        save_figure(fig, "../imgs/lcv_assets_bbox.png")
        return ax

    plot_assets()
    return


@app.cell(hide_code=True)
def _(BBOX, LogNorm, gpd, np):
    def dmg_norm():
        out = "/archive2/globc/seiche/marmande_2019_out"
        dmg = np.concatenate([
            gpd.read_file(
                f"{out}/dmg_hf_2019_k17_{s}_marmande.gpkg", bbox=BBOX.bounds
            )["dmg"].values
            for s in ("bdtopo", "sirene", "rpg")
        ])
        return LogNorm(vmin=dmg[dmg > 0].min(), vmax=dmg.max())

    return (dmg_norm,)


@app.cell(hide_code=True)
def _(BBOX, add_basemap, bbox_figure, bottom_colorbar, dmg_norm, gpd, np, plt):
    def plot_damage():
        out = "/archive2/globc/seiche/marmande_2019_out"
        files = {
            "BdTopo buildings": f"{out}/dmg_hf_2019_k17_bdtopo_marmande.gpkg",
            "Sirène establishments": f"{out}/dmg_hf_2019_k17_sirene_marmande.gpkg",
            "RPG parcels": f"{out}/dmg_hf_2019_k17_rpg_marmande.gpkg",
        }
        dfs = {
            name: gpd.read_file(path, bbox=BBOX.bounds)
            for name, path in files.items()
        }
        norm = dmg_norm()

        fig, ax = bbox_figure()
        add_basemap(ax)
        rpg = dfs["RPG parcels"]
        rpg[rpg["dmg"] > 0].plot(ax=ax, column="dmg", cmap="viridis", norm=norm,
                                 edgecolor="none", linewidth=0)
        bdt = dfs["BdTopo buildings"]
        bdt[bdt["dmg"] > 0].plot(ax=ax, column="dmg", cmap="viridis", norm=norm,
                                 edgecolor="k", linewidth=0.2)
        sir = dfs["Sirène establishments"]
        sir[sir["dmg"] > 0].plot(ax=ax, column="dmg", cmap="viridis", norm=norm,
                                 markersize=6, edgecolor="k", linewidth=0.3)

        sm = plt.cm.ScalarMappable(norm=norm, cmap="viridis")
        bottom_colorbar(fig, ax, sm, label="Damage (€2016 per vector)")
        save_figure(fig, "../imgs/dmg_hf_bbox.png")
        return ax

    plot_damage()
    return


@app.cell(hide_code=True)
def _(
    BBOX_GDF,
    add_basemap,
    bbox_figure,
    bottom_colorbar,
    dmg_norm,
    imshow_bbox,
    plt,
    reproj_clip,
    rxr,
):
    def plot_damage_raster():
        out = "/archive2/globc/seiche/marmande_2019_out"
        dmg = reproj_clip(
            rxr.open_rasterio(f"{out}/dmg_fwdet-l_esawc_marmande.tif").isel(band=0),
            2154, BBOX_GDF,
        )
        norm = dmg_norm()

        fig, ax = bbox_figure()
        add_basemap(ax)
        imshow_bbox(ax, dmg, cmap="viridis", norm=norm)
        sm = plt.cm.ScalarMappable(norm=norm, cmap="viridis")
        bottom_colorbar(fig, ax, sm, label="Damage (€2010 per pixel)")
        save_figure(fig, "../imgs/dmg_jrc_esawc_bbox.png")
        return ax

    plot_damage_raster()
    return


@app.cell(hide_code=True)
def _(BBOX_GDF, Rectangle, add_basemap, bbox_figure, bottom_colorbar, np, reproj_clip, rxr):
    def pop_fig(plotter, path):
        fig, ax = bbox_figure()
        add_basemap(ax)
        plotter(fig, ax)
        bottom_colorbar(fig, ax, ax.collections[0], label="Population")
        save_figure(fig, path)
        return ax

    def plot_ghsl(fig, ax):
        ghsl = rxr.open_rasterio(
            "/archive2/globc/seiche/marmande_2019_inp/ghslpop_2020.tif"
        ).rio.reproject("EPSG:2154")
        ghsl = reproj_clip(ghsl, 2154, BBOX_GDF).where(lambda d: d > 0)
        vals = ghsl.squeeze().values
        xs, ys = ghsl.x.values, ghsl.y.values
        dx, dy = xs[1] - xs[0], ys[1] - ys[0]
        ax.pcolormesh(xs, ys, np.ma.masked_invalid(vals),
                      cmap="Purples", vmin=0,
                      vmax=np.nanpercentile(vals, 99), alpha=0.8,
                      edgecolors="none")
        for i in range(vals.shape[0]):
            for j in range(vals.shape[1]):
                if not np.isnan(vals[i, j]):
                    ax.add_patch(Rectangle(
                        (xs[j] - dx / 2, ys[i] - dy / 2), dx, dy,
                        fill=False, edgecolor="black", linewidth=0.3,
                    ))

    return plot_ghsl, pop_fig


@app.cell(hide_code=True)
def _(plot_ghsl, pop_fig):
    pop_fig(plot_ghsl, "../imgs/pop_ghslpop_bbox.png")
    return


@app.cell(hide_code=True)
def _(BBOX, gpd, np, pop_fig):
    filosofi = gpd.read_file(
        "/archive2/globc/seiche/marmande_2019_inp/filosofi_2019.gpkg", bbox=BBOX.bounds
    )
    pop_fig(
        lambda fig, ax: filosofi.plot(
            ax=ax, column="ind", cmap="Purples", vmin=0,
            vmax=np.nanpercentile(filosofi["ind"], 99),
            edgecolor="black", linewidth=0.3, alpha=0.8,
        ),
        "../imgs/pop_filosofi_bbox.png",
    )
    return


@app.cell(hide_code=True)
def _(BBOX_GDF, bbox_figure_raster_plot, mcolors, mpatches, reproj_clip, rxr):
    def bfm_bbox_plot(path, out):
        da = reproj_clip(rxr.open_rasterio(path), 2154, BBOX_GDF).where(lambda d: d < 255)
        handles = [
            mpatches.Patch(facecolor="#0046C8", label="Flooded"),
            mpatches.Patch(facecolor="white", edgecolor="k", label="Not flooded"),
        ]
        return bbox_figure_raster_plot(
            da, out,
            cmap=mcolors.ListedColormap([(1, 1, 1, 0), (0, 0.275, 0.784, 0.9)]),
            vmin=0, vmax=1, basemap=True,
            legend=dict(handles=handles, loc="lower right", fontsize=8, frameon=True),
        )

    return bfm_bbox_plot


@app.cell(hide_code=True)
def _(bfm_bbox_plot):
    _, _ax = bfm_bbox_plot(
        "/archive2/globc/seiche/marmande_2019_inp/floodml/Inf_S1_L1C_30TYQ_20191215T060841_008_POST_MAJr03.tif",
        "../imgs/bfm_s1_bbox.png",
    )
    _ax
    return


@app.cell(hide_code=True)
def _(bfm_bbox_plot):
    _, _ax = bfm_bbox_plot(
        "/archive2/globc/seiche/marmande_2019_inp/floodml/Inf_S2_094_20191215T110441_POST_MAJr03_binary.tif",
        "../imgs/bfm_s2_bbox.png",
    )
    _ax
    return


@app.cell(hide_code=True)
def _(
    BBOX_GDF,
    DefendedMethod,
    bbox_figure_raster_plot,
    defended,
    np,
    reproj_clip,
    rxr,
):
    # FwDET-l and simple-e depths from the Sentinel-2 BFM of Fig. bfm-s1-s2-bbox,
    # with both the RGE Alti and GLO30 DEMs, on the shared 2x2 km bbox.
    bfm = reproj_clip(
        rxr.open_rasterio(
            "/archive2/globc/seiche/marmande_2019_inp/floodml/Inf_S2_094_20191215T110441_POST_MAJr03_binary.tif"
        ),
        2154,
        BBOX_GDF,
    )
    dems = {
        "rge_alti": ("RGE Alti (1 m)", "/archive2/globc/seiche/marmande_2019_inp/rge_alti.tif"),
        "glo30": ("GLO30 (30 m)", "/archive2/globc/seiche/marmande_2019_inp/demglo30_2011-part1.tif"),
    }
    dem_da = {
        key: reproj_clip(rxr.open_rasterio(path), 2154, BBOX_GDF)
        for key, (_, path) in dems.items()
    }
    methods = {
        "fwdet_l": ("FwDET-l", DefendedMethod.fwdet_l),
        "simple_e": ("simple-e", DefendedMethod.simple_e),
    }

    depths = {
        (method_key, dem_key): defended(method_enum, bfm, dem_da[dem_key])
        for method_key, (_, method_enum) in methods.items()
        for dem_key in dems
    }
    vmax = float(
        np.nanmax(
            np.concatenate(
                [da.values[np.isfinite(da.values)] for da in depths.values()]
            )
        )
    )

    def plot_depth(da, path, label):
        return bbox_figure_raster_plot(
            da, path, label=label, cmap="Reds", vmin=0, vmax=vmax,
            basemap=True, outline=True,
        )

    return depths, plot_depth, vmax


@app.cell(hide_code=True)
def _(depths, plot_depth):
    _, _ax = plot_depth(
        depths[("fwdet_l", "rge_alti")],
        "../imgs/depth_fwdet_l_rge_alti_bbox.png",
        label="Water depth (m) · FwDET-l · RGE Alti (1 m)",
    )
    _ax
    return


@app.cell(hide_code=True)
def _(depths, plot_depth):
    _, _ax = plot_depth(
        depths[("fwdet_l", "glo30")],
        "../imgs/depth_fwdet_l_glo30_bbox.png",
        label="Water depth (m) · FwDET-l · GLO30 (30 m)",
    )
    _ax
    return


@app.cell(hide_code=True)
def _(depths, plot_depth):
    _, _ax = plot_depth(
        depths[("simple_e", "rge_alti")],
        "../imgs/depth_simple_e_rge_alti_bbox.png",
        label="Water depth (m) · simple-e · RGE Alti (1 m)",
    )
    _ax
    return


@app.cell(hide_code=True)
def _(depths, plot_depth):
    _, _ax = plot_depth(
        depths[("simple_e", "glo30")],
        "../imgs/depth_simple_e_glo30_bbox.png",
        label="Water depth (m) · simple-e · GLO30 (30 m)",
    )
    _ax
    return


@app.cell(hide_code=True)
def _(pd, plt):
    def plot_insitu_stomer():
        BASE = "/archive2/globc/seiche/stomer_inp/insitu/ObsHDF2324_AOI.parquet"
        df = pd.read_parquet(BASE)
        df["Date"] = pd.to_datetime(df["Date d'observation hydrométrique"])
        df["level"] = pd.to_numeric(
            df["Résultat de l'observation hydrométrique"], errors="coerce"
        )
        df = df[df["level"] > 0]

        fig, ax = plt.subplots(figsize=(6.5, 4))
        for site, g in df.groupby("Code du site hydrométrique"):
            g = g.sort_values("Date")
            if len(g) < 500:
                continue
            ax.plot(g["Date"], g["level"], lw=0.7, label=site)
        ax.set_ylabel("Water level (m)")
        ax.set_title("In-situ water levels in the SmageAa watershed (2023-2024)")
        ax.legend(fontsize=7, ncol=2)
        ax.grid(alpha=0.3)
        fig.autofmt_xdate()
        fig.tight_layout()
        save_figure(fig, "../imgs/insitu_stomer.png")
        return ax

    plot_insitu_stomer()
    return


@app.cell(hide_code=True)
def _(pd, plt):
    # Parameter sweeps: death toll vs. dam height / peak flux / warning lead time.
    SWEEP_SUMMARIES = [
        (
            "Malpasset dam breach (1959)",
            "/data/scratch/globc/garin/sim_out/malpasset/sweep/summary.csv",
            "dam_height_final",
            "Dam breach size (m)",
            lambda height: 66.0 - height,
        ),
        (
            "Garonne flood at Toulouse (1875)",
            "/data/scratch/globc/garin/sim_out/garonne_1875/sweep/summary.csv",
            "peak_flux",
            "Peak river flux (m$^3$/s)",
            None,
        ),
        (
            "Malpasset dam breach (1959), full collapse",
            "/data/scratch/globc/garin/sim_out/malpasset/sweep_warning/summary.csv",
            "warning_lead_time",
            "Warning lead time (min)",
            lambda t: t / 60.0,
        ),
        (
            "Garonne flood at Toulouse (1875), 8,000 m$^3$/s",
            "/data/scratch/globc/garin/sim_out/garonne_1875/sweep_warning/summary.csv",
            "warning_lead_time",
            "Warning lead time (h)",
            lambda t: t / 3600.0,
        ),
    ]

    def sweep_plot(series, path):
        fig, axes = plt.subplots(1, 2, figsize=(12, 4.2), layout="constrained")
        for ax, (title, file, xcol, xlabel, to_x) in zip(axes, series):
            df = pd.read_csv(file).sort_values(xcol)
            x = df[xcol] if to_x is None else to_x(df[xcol])
            ax.plot(x, df["n_dead"], marker="o", color="#d62728")
            ax.set_title(title)
            ax.set_xlabel(xlabel)
            ax.set_ylabel("Dead agents")
            ax.grid(True, alpha=0.6, lw=0.5)
        save_figure(fig, path)
        return fig

    return SWEEP_SUMMARIES, sweep_plot


@app.cell(hide_code=True)
def _(SWEEP_SUMMARIES, sweep_plot):
    sweep_plot(SWEEP_SUMMARIES[:2], "../imgs/sdc.png")
    return


@app.cell(hide_code=True)
def _(SWEEP_SUMMARIES, sweep_plot):
    sweep_plot(SWEEP_SUMMARIES[2:], "../imgs/sdc_warning_time.png")
    return


@app.cell(hide_code=True)
def _(np, pd, plt):
    # Death fraction by agent vulnerability and risk perception (warning cases).
    REFERENCE_CASES = [
        (
            "Malpasset dam breach (1959), 13 min warning",
            "/data/scratch/globc/garin/sim_out/malpasset/sweep_warning/warning_lead_time_800.0",
        ),
        (
            "Garonne flood at Toulouse (1875), 5.3 h warning",
            "/data/scratch/globc/garin/sim_out/garonne_1875/sweep_warning/warning_lead_time_19200.0",
        ),
    ]

    def load_civilians(case_dir):
        init = pd.read_csv(f"{case_dir}/agents_init.csv")
        data = pd.read_csv(f"{case_dir}/data.csv", usecols=["time", "id", "status"])
        last = data[data.time == data.time.max()][["id", "status"]]
        agents = init.merge(last, on="id")
        agents = agents[agents.role == "civilian"]
        agents["dead"] = (agents.status == "dead").astype(int)
        return agents

    def plot_attribute_curves():
        fig, axes = plt.subplots(2, 2, figsize=(12, 8), layout="constrained")
        for row, (title, case_dir) in enumerate(REFERENCE_CASES):
            agents = load_civilians(case_dir)
            for col, attr in enumerate(["vulnerability", "risk_perception"]):
                ax = axes[row, col]
                bins = np.linspace(0, 1, 11)
                groups = pd.cut(agents[attr], bins, include_lowest=True)
                rate = agents.groupby(groups, observed=True)["dead"].agg(["mean", "count"])
                centers = [iv.mid for iv in rate.index]
                ax.plot(centers, rate["mean"], marker="o", color="#d62728")
                ax.set_title(f"{title} - {attr.replace('_', ' ')}")
                ax.set_xlabel(attr.replace("_", " "))
                ax.set_ylabel("Death fraction")
                ax.set_ylim(0, 1)
                ax.grid(True, alpha=0.6, lw=0.5)
        save_figure(fig, "../imgs/sdc_agent_attributes.png")
        return fig

    plot_attribute_curves()
    return


@app.cell(hide_code=True)
def _(np, pd, plt):
    # Input river hydrograph of the Garonne 1875 test case: the synthetic
    # asymmetric Gaussian flux written by FSFS write_river_sources for the
    # river source (base 200 m3/s, peak 8,000 m3/s, 600 s time step, 96 h).
    RIVER_SOURCE = "/data/scratch/globc/garin/sim_out/garonne_1875/sweep/river_source_peak_flux_8000.0/river-sources.csv"

    def plot_input_flow():
        flux = pd.read_csv(RIVER_SOURCE, header=None).iloc[0, 2:].to_numpy(dtype=float)
        t = np.arange(len(flux)) * 600.0 / 3600.0  # 600 s time step -> hours
        peak, i_peak = flux.max(), int(flux.argmax())

        fig, ax = plt.subplots(figsize=(7.2, 4.2), layout="constrained")
        ax.plot(t, flux, color="#1f77b4", lw=1.2)
        ax.axhline(peak, ls="--", lw=0.8, color="#888888")
        ax.axvline(t[i_peak], ls=":", lw=1.0, color="#888888")
        ax.set_title("Input river flow of the Garonne 1875 test case")
        ax.set_xlabel("Time (h)")
        ax.set_ylabel("River flow (m$^3$/s)")
        ax.set_xlim(0, 96)
        ax.set_ylim(0, 8800)
        ax.grid(True, alpha=0.6, lw=0.5)
        save_figure(fig, "../imgs/fsfs_input_flow_garonne.png")
        return fig

    plot_input_flow()
    return


@app.cell(hide_code=True)
def _(ConnectionPatch, LightSource, Rectangle, add_basemap, mcolors, np, pd, plt, rxr, xy):
    # FSFS simulation snapshots: one figure per example case, with the full
    # domain on OSM (flood at 50% transparency, snapshot window in red) on the
    # left, the 3x3 km zoom with the agents on the right, and the legend on the
    # right of the zoom. The same plotting function is reused for both cases.
    CASES = [
        {
            "name": "malpasset",
            "case": "/data/scratch/globc/garin/sim_out/malpasset/sweep_warning/warning_lead_time_800.0",
            "dem": "/data/scratch/globc/garin/fsfs_cache/6.7_43.38_6.82_43.54_z12_res30.0/dem.tif",
            "step": 20,
            "r0": 515,
            "c0": 5,
            "win": 100,
        },
        {
            "name": "garonne",
            "case": "/data/scratch/globc/garin/sim_out/garonne_1875/sweep/river_source_peak_flux_8000.0",
            "dem": "/data/scratch/globc/garin/fsfs_cache/1.25_43.42_1.55_43.8_z12_res50.0/dem.tif",
            "step": 200,
            "r0": 260,
            "c0": 240,
            "win": 60,
        },
    ]
    STATUS_COLORS = {"safe": "#33cc33", "danger": "#ff9900", "dead": "#cc1111"}

    def plot_fsfs_figure(s):
        t = s["step"]
        df = pd.read_csv(
            f"{s['case']}/data.csv",
            usecols=["time", "id", "status", "col", "row"],
            dtype={
                "time": "int16", "id": "int32", "status": "category",
                "col": "int16", "row": "int16",
            },
        )
        sub = df[df.time == t]
        with rxr.open_rasterio(f"{s['case']}/depth-001-{t:05d}.tif") as d:
            tr = d.rio.transform()
            H, W = d.shape[-2], d.shape[-1]
            depth = np.asarray(d.squeeze().values, dtype=np.float32)
            sub = sub.copy()
            sub["col"] = sub.col.clip(0, W - 1)
            sub["row"] = sub.row.clip(0, H - 1)
        with rxr.open_rasterio(s["dem"]) as dem:
            dem = np.asarray(dem.squeeze().values, dtype=np.float32)
        cache_dir = s["dem"].rsplit("/", 1)[0]
        with rxr.open_rasterio(f"{cache_dir}/buildings.tif") as b:
            buildings = np.asarray(b.squeeze().values, dtype=bool)
        extraction = pd.read_csv(f"{cache_dir}/extraction_points.csv")
        r0, c0, w = s["r0"], s["c0"], s["win"]

        panel_h = 3.6
        loc_ratio = (W * abs(tr.a)) / (H * abs(tr.e))  # domain width / height
        fig = plt.figure(figsize=(panel_h * (loc_ratio + 1.7 + 0.08), panel_h * 1.7))
        gs = fig.add_gridspec(1, 2, width_ratios=[loc_ratio, 1.7], wspace=0.02)
        gs0 = gs[0].subgridspec(2, 1, height_ratios=[1.0, 1.25], hspace=0.05)
        axloc = fig.add_subplot(gs0[0])
        axleg = fig.add_subplot(gs0[1])
        axzoom = fig.add_subplot(gs[1])

        # --- full domain on OSM ---
        axloc.set_xlim(tr.c, tr.c + W * tr.a)
        axloc.set_ylim(tr.f + H * tr.e, tr.f)
        axloc.set_aspect("equal")
        add_basemap(axloc, crs="EPSG:3857")
        im_loc = axloc.imshow(
            np.ma.masked_where(depth < 0.1, depth),
            cmap="Blues", vmin=0, vmax=3, alpha=0.5,
            extent=[tr.c, tr.c + W * tr.a, tr.f + H * tr.e, tr.f],
        )
        axloc.add_patch(
            Rectangle(
                (tr.c + c0 * tr.a, tr.f + (r0 + w) * tr.e),
                w * tr.a, w * abs(tr.e),
                fill=False, edgecolor="red", lw=1.5,
            )
        )
        # zoom connectors: red rectangle right corners -> zoom panel left edge
        x_win1 = tr.c + (c0 + w) * tr.a
        y_win0 = tr.f + (r0 + w) * tr.e
        y_win1 = tr.f + r0 * tr.e
        for y_win in (y_win0, y_win1):
            fig.add_artist(
                ConnectionPatch(
                    xyA=(x_win1, y_win), coordsA=axloc.transData,
                    xyB=(0, 3 if y_win == y_win1 else 0), coordsB=axzoom.transData,
                    color="red", lw=1.2, alpha=0.9, zorder=1,
                )
            )
        axloc.set_xticks([])
        axloc.set_yticks([])

        # --- 3x3 km zoom ---
        hill = LightSource(azdeg=315, altdeg=45).hillshade(
            dem[r0:r0 + w, c0:c0 + w], vert_exag=3
        )
        axzoom.imshow(hill, cmap="gray", extent=[0, 3, 0, 3])
        axzoom.imshow(
            np.ma.masked_where(depth[r0:r0 + w, c0:c0 + w] < 0.1, depth[r0:r0 + w, c0:c0 + w]),
            cmap="Blues", vmin=0, vmax=3, alpha=0.75, extent=[0, 3, 0, 3],
        )
        # buildings as pink blocks, extraction points as purple triangles
        bwin = buildings[r0:r0 + w, c0:c0 + w]
        axzoom.imshow(
            np.ma.masked_where(~bwin, bwin),
            cmap=mcolors.ListedColormap(["#ff69b4"]), vmin=0, vmax=1, alpha=0.85,
            extent=[0, 3, 0, 3],
        )
        p = extraction[
            extraction.col.between(c0, c0 + w - 1)
            & extraction.row.between(r0, r0 + w - 1)
        ]
        if len(p):
            px, py = xy(tr, p.row.values, p.col.values, offset="center")
            axzoom.scatter(
                (px - tr.c - c0 * tr.a) / 1000,
                (py - tr.f - (r0 + w) * tr.e) / 1000,
                marker="^", s=45, c="#800080", edgecolors="white", linewidths=0.6,
            )
        for status, color in STATUS_COLORS.items():
            p = sub[
                (sub.status == status)
                & (sub.col.between(c0, c0 + w - 1))
                & (sub.row.between(r0, r0 + w - 1))
            ]
            if len(p):
                agg = p.groupby(["col", "row"], observed=True).size().reset_index(name="n")
                px, py = xy(tr, agg.row.values, agg.col.values, offset="center")
                axzoom.scatter(
                    (px - tr.c - c0 * tr.a) / 1000,
                    (py - tr.f - (r0 + w) * tr.e) / 1000,
                    s=2.2 * agg.n.values + 10, c=color, alpha=0.75,
                    edgecolors="black", linewidths=0.4,
                    label=status,
                )
        axzoom.set_xlim(0, 3)
        axzoom.set_ylim(0, 3)
        axzoom.set_aspect("equal")
        axzoom.set_xticks([])
        axzoom.set_yticks([])
        for spine in axzoom.spines.values():
            spine.set_color("red")
            spine.set_linewidth(1.5)

        # --- legend below the full domain, drawn manually so that axleg (zorder 10)
        # covers the figure-level connector lines while they stay above the OSM ---
        axleg.set_zorder(10)
        axleg.axis("off")
        entries = [
            (9.0, STATUS_COLORS["safe"], "safe", "o"),
            (9.0, STATUS_COLORS["danger"], "danger", "o"),
            (9.0, STATUS_COLORS["dead"], "dead", "o"),
            (9.0, "#ff69b4", "building", "s"),
            (9.0, "#800080", "extraction\npoint", "^"),
            (np.sqrt(2.2 * 10 + 10), "#888888", "10 agents", "o"),
            (np.sqrt(2.2 * 100 + 10), "#888888", "100 agents", "o"),
            (np.sqrt(2.2 * 500 + 10), "#888888", "500 agents", "o"),
        ]
        row_h = 1.0 / (len(entries) + 0.6)
        pad = 0.025
        fig.canvas.draw()
        renderer = fig.canvas.get_renderer()
        inv = axleg.transAxes.inverted()
        bb = axleg.get_window_extent(renderer)
        pt_x = renderer.points_to_pixels(1.0) / bb.width
        pt_y = renderer.points_to_pixels(1.0) / bb.height
        # rows spaced by their own content (marker diameter, or text height for
        # two-line labels) so the large agent circles never overlap
        line_pt = 8 * 1.4
        row_pts = [
            max(ms, (label.count("\n") + 1) * line_pt) + 6
            for ms, _, label, _ in entries
        ]
        # align the legend box with the OSM map's left edge
        map_x0 = inv.transform((im_loc.get_window_extent(renderer).x0, 0))[0]
        x_center = map_x0 + entries[-1][0] / 2 * pt_x + pad
        placed = []
        y_top = 0.97
        for (ms, color, label, marker), h_pt in zip(entries, row_pts):
            y = y_top - h_pt * pt_y / 2
            y_top -= h_pt * pt_y
            m = axleg.scatter([x_center], [y], s=ms**2, c=color, marker=marker,
                              edgecolors="black", linewidths=0.5,
                              transform=axleg.transAxes, zorder=2, clip_on=False)
            t = axleg.text(x_center + 0.30, y, label, transform=axleg.transAxes,
                           va="center", ha="left", fontsize=8, zorder=2)
            placed.append((ms, y, m, t))
        # white box fitted around the measured entry extents
        pts = []
        for ms, y, m, t in placed:
            r_x = ms / 2 * pt_x
            r_y = ms / 2 * pt_y
            pts += [(x_center - r_x, y - r_y), (x_center + r_x, y + r_y)]
            pts.extend(inv.transform(t.get_window_extent(renderer).corners()))
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        axleg.add_patch(
            Rectangle((min(xs) - pad, min(ys) - pad),
                      max(xs) - min(xs) + 2 * pad,
                      max(ys) - min(ys) + 2 * pad,
                      transform=axleg.transAxes,
                      facecolor="white", edgecolor="black", lw=0.8, zorder=1,
                      clip_on=False)
        )
        save_figure(fig, f"../imgs/fsfs_snapshot_{s['name']}.png")
        return fig

    return CASES, STATUS_COLORS, plot_fsfs_figure


@app.cell(hide_code=True)
def _(CASES, plot_fsfs_figure):
    plot_fsfs_figure(CASES[0])
    return


@app.cell(hide_code=True)
def _(CASES, plot_fsfs_figure):
    plot_fsfs_figure(CASES[1])
    return


@app.cell(hide_code=True)
def _(LightSource, add_basemap, np, plt, rxr):
    # Raster inputs of the two example simulations: OSM basemap, DEM
    # (hillshade), Manning coefficients, building mask and WorldPop population.
    # One row per case; the Manning and population colorbars are shared between
    # the two rows and drawn below the subplots.
    INPUT_CASES = [
        ("Malpasset", "/data/scratch/globc/garin/fsfs_cache/6.7_43.38_6.82_43.54_z12_res30.0"),
        ("Garonne at Toulouse", "/data/scratch/globc/garin/fsfs_cache/1.25_43.42_1.55_43.8_z12_res50.0"),
    ]
    PANELS = ["OSM", "DEM", "Manning", "Buildings", "Population"]

    def load(datadir, fname):
        with rxr.open_rasterio(f"{datadir}/{fname}") as r:
            a = np.asarray(r.squeeze().values, dtype=np.float32)
            tr = r.rio.transform()
        extent = (tr.c, tr.c + a.shape[1] * tr.a, tr.f + a.shape[0] * tr.e, tr.f)
        return a, extent

    def plot_inputs():
        data = {}
        for title, datadir in INPUT_CASES:
            dem, extent = load(datadir, "dem.tif")
            data[title] = {
                "extent": extent,
                "dem": dem,
                "manning": load(datadir, "manning.tif")[0],
                "buildings": load(datadir, "buildings.tif")[0],
                "pop": load(datadir, "population_FRA_2020.tif")[0],
            }
        pop_vmax = max(np.nanmax(d["pop"]) for d in data.values())
        manning_vmax = max(np.nanmax(d["manning"]) for d in data.values())

        fig = plt.figure(figsize=(9.6, 5.6))
        gs = fig.add_gridspec(
            3, 5, height_ratios=(1, 1, 0.06), hspace=0.03, wspace=0.02
        )
        axes = gs.subplots()
        for col in (0, 1, 3):  # unused bottom cells: only Manning and Population get a colorbar
            axes[2, col].axis("off")

        for row, (title, _) in enumerate(INPUT_CASES):
            d = data[title]
            extent = d["extent"]

            ax = axes[row, 0]
            ax.set_xlim(extent[0], extent[1])
            ax.set_ylim(extent[2], extent[3])
            ax.set_aspect("auto")
            add_basemap(ax, crs="EPSG:3857", alpha=None)

            ax = axes[row, 1]
            hill = LightSource(azdeg=315, altdeg=45).hillshade(d["dem"], vert_exag=3)
            ax.imshow(hill, cmap="gray", extent=extent, aspect="auto")

            ax = axes[row, 2]
            im = ax.imshow(d["manning"], cmap="cividis", vmin=0, vmax=manning_vmax, extent=extent, aspect="auto")
            if row == 0:
                fig.colorbar(im, cax=axes[2, 2], orientation="horizontal")

            ax = axes[row, 3]
            ax.imshow(d["buildings"], cmap="Greys", vmin=0, vmax=1, extent=extent, aspect="auto")

            ax = axes[row, 4]
            im = ax.imshow(d["pop"], cmap="viridis", vmin=0, vmax=pop_vmax, extent=extent, aspect="auto")
            if row == 0:
                fig.colorbar(im, cax=axes[2, 4], orientation="horizontal")

            for col, name in enumerate(PANELS):
                a = axes[row, col]
                if row == 0:  # panel names only on the top row
                    a.set_title(name, fontsize=8)
                a.set_xticks([])
                a.set_yticks([])
                if col == 0:
                    a.set_ylabel(title, fontsize=8)
        save_figure(fig, "../imgs/fsfs_inputs.png")
        return fig

    plot_inputs()
    return


@app.cell(hide_code=True)
def _(ccrs, cfeature, plt):
    # Approximate test case locations (lon, lat) and label offsets in points.
    # The test cases span more than a hemisphere, so a single orthographic
    # globe cannot show them all: the French cases and Nokoué are shown on
    # both views for context.
    _CASES = {
        "Ohio":        dict(lon=-87.10, lat=37.87, globes=(0,), dx=5, dy=0),
        "St-Omer":     dict(lon=2.14,  lat=50.69, globes=(0, 1), dx=5, dy=7),
        "Chinon":      dict(lon=0.24,  lat=47.17, globes=(0, 1), dx=5, dy=0),
        "Marmande":    dict(lon=0.14,  lat=44.48, globes=(0, 1), dx=5, dy=-9),
        "Nokoué":      dict(lon=2.44,  lat=6.43,  globes=(0, 1), dx=5, dy=0),
        "Tonle Sap":   dict(lon=104.10, lat=12.90, globes=(1,), dx=-5, dy=0),
    }
    GLOBES = [(-30, 30), (60, 20)]  # Atlantic side, Indian side

    def plot_test_cases_map():
        fig = plt.figure(figsize=(10, 5))
        for i, (lon0, lat0) in enumerate(GLOBES):
            ax = fig.add_axes(
                [i / 2 + 0.01, 0, 0.48, 1], projection=ccrs.Orthographic(lon0, lat0)
            )
            ax.set_global()
            ax.add_feature(cfeature.OCEAN, color="#cfe3f7")
            ax.add_feature(cfeature.LAND, color="#f2efe9")
            ax.add_feature(cfeature.BORDERS, linewidth=0.4)
            ax.add_feature(cfeature.COASTLINE, linewidth=0.4)
            ax.gridlines(color="gray", linewidth=0.3, linestyle=":")

            for name, c in _CASES.items():
                if i not in c["globes"]:
                    continue
                ax.plot(
                    c["lon"], c["lat"], "o", color="crimson", markersize=5,
                    transform=ccrs.PlateCarree(), zorder=5,
                )
                ax.annotate(
                    name, (c["lon"], c["lat"]), xytext=(c["dx"], c["dy"]),
                    textcoords="offset points", fontsize=8,
                    ha="right" if c["dx"] < 0 else "left",
                    transform=ccrs.PlateCarree(), zorder=5,
                )
        save_figure(fig, "../imgs/test_cases_map.png")
        return fig

    plot_test_cases_map()
    return


if __name__ == "__main__":
    app.run()
