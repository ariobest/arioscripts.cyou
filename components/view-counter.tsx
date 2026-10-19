"use client";

import { useEffect } from "react";
import { createClient } from "@/lib/supabase/client";

export default function ViewCounter({ id }: { id: string }) {
  useEffect(() => {
    const incrementView = async () => {
      try {
        await createClient().rpc("increment_script_view", {
          script_id_input: id,
        });
      } catch {
        // View tracking should never break the page.
      }
    };

    void incrementView();
  }, [id]);

  return null;
}
