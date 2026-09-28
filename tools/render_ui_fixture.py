"""Render recorded Lua UI geometry for offline review; not a WoW screenshot."""
import json, re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageChops

ROOT=Path(__file__).resolve().parents[1]
FONT="C:/Windows/Fonts/msyh.ttc"
def render(name, width, height, crop=None):
    objects=json.loads((ROOT/"Analyze"/(name+".json")).read_text(encoding="utf-8"))
    nodes={n["id"]:n for n in objects}; rects={}
    def font(n): return ImageFont.truetype(FONT,n.get("fontSize",16))
    def plain(s): return re.sub(r"\|c[0-9a-fA-F]{8}|\|r","",s)
    def factors(anchor):
        return (0 if "LEFT" in anchor else 1 if "RIGHT" in anchor else .5,
                0 if "TOP" in anchor else 1 if "BOTTOM" in anchor else .5)
    def rect(i):
        if i in rects:return rects[i]
        n=nodes[i]; p=n.get("parent",{}).get("ref")
        parent=rect(p) if p else (0,0,1920,1080)
        if "allPoints" in n:
            result=rect(n["allPoints"]["ref"]);rects[i]=result;return result
        text=plain(n.get("text",""));size=n.get("fontSize",16)
        w=n.get("width",font(n).getlength(text) if n["kind"]=="FontString" else parent[2])
        h=n.get("height",size*1.35 if n["kind"]=="FontString" else parent[3])
        constraints=[[],[]]
        for anchor in n.get("points",[]):
            a=anchor[0]; x=y=0;relative=a;target=parent
            if len(anchor)>1 and isinstance(anchor[1],dict):
                target=rect(anchor[1]["ref"]);relative=anchor[2];x,y=anchor[3:5]
            elif len(anchor)>2:x,y=anchor[1:3]
            f=factors(a);g=factors(relative)
            constraints[0].append((f[0],target[0]+g[0]*target[2]+x))
            constraints[1].append((f[1],target[1]+g[1]*target[3]-y))
        vals=[]
        for dim,cs in zip((w,h),constraints):
            if len(cs)>1 and cs[0][0]!=cs[1][0]:dim=(cs[1][1]-cs[0][1])/(cs[1][0]-cs[0][0])
            origin=cs[0][1]-cs[0][0]*dim if cs else 0
            vals.append((origin,dim))
        result=(vals[0][0],vals[1][0],max(.01,vals[0][1]),max(.01,vals[1][1]));rects[i]=result;return result
    def visible(n):
        return n.get("shown",True) and ("parent" not in n or visible(nodes[n["parent"]["ref"]]))
    def color(value):return tuple(round(v*255) for v in value[:3])+(round((value[3] if len(value)>3 else 1)*255),)
    im=Image.new("RGBA",(width,height),(14,14,16,255));draw=ImageDraw.Draw(im)
    ox,oy=(crop or (0,0))
    def layer(n):
        parent=nodes.get(n.get("parent",{}).get("ref"))
        strata,level=layer(parent) if parent else (0,0)
        if n.get("strata")=="DIALOG":strata=10
        if n["kind"] not in ("Texture","FontString"):level+=1
        return strata,level
    for n in sorted(objects,key=lambda n:(*layer(n),n["kind"] in ("FontString","EditBox"),n["id"])):
            kind=n["kind"]
            if kind not in ("Texture","FontString","EditBox") or not visible(n):continue
            if kind=="EditBox" and not n.get("text"):continue
            x,y,w,h=rect(n["id"]);x-=ox;y-=oy
            box=(round(x),round(y),round(x+w),round(y+h))
            if kind=="Texture":
                if "texture" in n:
                    path=ROOT/"addon"/n["texture"].replace("Interface\\AddOns\\", "").replace("\\","/")
                    asset=Image.open(path).convert("RGBA")
                    a,b,c,d=n.get("texCoord",[0,1,0,1]);aw,ah=asset.size
                    asset=asset.crop((min(a,b)*aw,min(c,d)*ah,max(a,b)*aw,max(c,d)*ah))
                    if a>b:asset=asset.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                    if c>d:asset=asset.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
                    asset=asset.resize((max(1,round(w)),max(1,round(h))),Image.Resampling.LANCZOS)
                    if "tint" in n:asset=ImageChops.multiply(asset,Image.new("RGBA",asset.size,color(n["tint"])))
                    im.paste(asset,(round(x),round(y)),asset)
                elif "color" in n:draw.rectangle(box,fill=color(n["color"]))
            else:
                text=n.get("text","");f=font(n);whole=plain(text);available=w
                if "width" in n or len(n.get("points",[]))>1:
                    if f.getlength(whole)>available:
                        while whole and f.getlength(whole+"…")>available:whole=whole[:-1]
                        text=whole+"…"
                if n.get("justify")=="RIGHT":x+=max(0,w-f.getlength(plain(text)))
                tint=color(n.get("textColor",[.94,.932,.91]));base=tint
                for chunk in re.split(r"(\|c[0-9a-fA-F]{8}|\|r)",text):
                    if chunk=="|r":tint=base
                    elif chunk.startswith("|c"):tint=tuple(int(chunk[i:i+2],16) for i in (4,6,8))+(255,)
                    else:draw.text((x,y),chunk,font=f,fill=tint,anchor="lt");x+=f.getlength(chunk)
    path=ROOT/"Analyze"/(name+".png");im.convert("RGB").save(path)
    return path

if __name__=="__main__":
    for w in (640,480):print(render(f"ui-settings-{w}",w+26,768))
    for name in ("ui-credits","ui-downloads"):print(render(name,666,768))
    # The fixture mover is centered on a 1920x1080 UIParent.
    print(render("ui-mover",440,156,(740,302)))
