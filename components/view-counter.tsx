"use client";
import {useEffect} from "react";import {createClient} from "@/lib/supabase/client";
export default function ViewCounter({id}:{id:string}){useEffect(()=>{createClient().rpc("increment_script_view",{script_id_input:id}).then(()=>{}).catch(()=>{})},[id]);return null;}