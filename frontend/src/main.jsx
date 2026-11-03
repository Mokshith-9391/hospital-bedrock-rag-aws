import React, {useState} from "react";
import {createRoot} from "react-dom/client";
import "./style.css";

function App(){
 const [q,setQ]=useState(""); const [a,setA]=useState(""); const [busy,setBusy]=useState(false);
 async function ask(){
   setBusy(true); setA("");
   try{
     const token = localStorage.getItem("id_token");
     const r=await fetch(import.meta.env.VITE_API_URL+"/query",{
       method:"POST",headers:{"content-type":"application/json","Authorization":"Bearer "+token},
       body:JSON.stringify({question:q})
     });
     const d=await r.json(); setA(d.answer||d.error);
   }catch(e){setA("Request failed");} finally{setBusy(false);}
 }
 return <main><h1>Hospital Knowledge Assistant</h1>
 <p>Grounded answers from approved hospital documents.</p>
 <textarea value={q} onChange={e=>setQ(e.target.value)} placeholder="Ask about a hospital policy or procedure..."/>
 <button onClick={ask} disabled={busy}>{busy?"Searching...":"Ask"}</button>
 <pre>{a}</pre>
 </main>
}
createRoot(document.getElementById("root")).render(<App/>);