-- Test des codes d'accès : à coller dans Supabase > SQL Editor > Run APRÈS la migration 0010.
-- Tout le test s'annule à la fin. Résultat attendu : « OK : codes d'accès vérifiés ».
do $test$
declare
  alice constant uuid := '00000000-0000-0000-0000-0000000000c1';
  bob   constant uuid := '00000000-0000-0000-0000-0000000000c2';
  k text; a uuid; n int;
begin
  delete from auth.users where id in (alice, bob);
  begin
    insert into auth.users (id, email, raw_user_meta_data) values
      (alice, 'c1@test.flo', '{"first_name":"Alice"}'), (bob, 'c2@test.flo', '{"first_name":"Bob"}');
    update public.flo_reglages set code_obligatoire = true;
    k := public.nouveau_code('Test');
    if k !~ '^FLO-[A-Z2-9]{4}-[A-Z2-9]{4}$' then raise exception 'format de code inattendu : %', k; end if;

    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', bob)::text, true);
    -- Sans code, avec un faux code : refusé.
    begin perform public.create_organization('Sans code', null, null); raise exception 'créée sans code';
    exception when sqlstate 'FL010' then null; end;
    begin perform public.create_organization('Faux code', null, null, 'FLO-AAAA-AAAA'); raise exception 'créée avec un faux code';
    exception when sqlstate 'FL010' then null; end;
    -- Un utilisateur ne peut pas fabriquer de code ni lire la liste.
    begin perform public.nouveau_code('pirate'); raise exception 'code créé par un utilisateur';
    exception when insufficient_privilege then null; end;
    select count(*) into n from public.codes_acces;
    if n <> 0 then raise exception 'codes visibles par un utilisateur'; end if;

    -- Alice, avec le bon code (en minuscules, avec des espaces) : acceptée.
    perform set_config('request.jwt.claims', json_build_object('sub', alice)::text, true);
    a := public.create_organization('Plomberie Alice', null, null, '  ' || lower(k) || ' ');
    if a is null then raise exception 'entreprise non créée'; end if;

    -- Le code ne sert qu'une fois.
    perform set_config('request.jwt.claims', json_build_object('sub', bob)::text, true);
    begin perform public.create_organization('Deuxième fois', null, null, k); raise exception 'code réutilisé';
    exception when sqlstate 'FL010' then null; end;
    reset role;

    select count(*) into n from public.codes_acces where code = k and used_by = alice and organization_id = a;
    if n <> 1 then raise exception 'code non rattaché à l''entreprise'; end if;

    raise notice 'OK : codes d''accès vérifiés (aucune donnée de test conservée)';
    raise exception using errcode = 'FL000';
  exception when sqlstate 'FL000' then null;
  end;
end $test$;
